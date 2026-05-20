import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/exceptions/signing_cancelled_exception.dart';
import 'package:realunit_wallet/packages/wallet/wallet_account.dart';

abstract class DFXAuthService {
  static const walletName = 'RealUnit';
  static const _signMessageTimeout = Duration(minutes: 3);
  static const _httpTimeout = Duration(seconds: 20);

  final String signMessagePath = '/v1/auth/signMessage';
  final String authPath = '/v1/auth';
  final AppStore appStore;
  final WalletService walletService;

  DFXAuthService(this.appStore, this.walletService);

  String get host => appStore.apiConfig.apiHost;

  AWalletAccount get wallet => appStore.wallet.currentAccount;

  String get walletAddress => wallet.primaryAddress.address.hexEip55;

  Future<String> getSignMessage() => _fetchSignMessage(walletAddress);

  /// Create-and-persist the auth signature for [account] without going through
  /// `appStore.wallet`. Used during the BitBox pairing flow so the signature is
  /// captured while the hardware wallet is guaranteed connected — every
  /// subsequent buy / KYC / user-data call can then run off the cached
  /// signature without needing the BitBox.
  ///
  /// No-op if a signature for this address is already in the cache.
  Future<void> ensureSignatureFor(AWalletAccount account) async {
    final address = account.primaryAddress.address.hexEip55;
    await appStore.sessionCache.loadSignature();
    if (appStore.sessionCache.signature != null &&
        appStore.sessionCache.signatureAddress == address) {
      return;
    }

    final message = await _fetchSignMessage(address);
    final signature = await account.signMessage(message).timeout(_signMessageTimeout);
    if (signature.isEmpty || signature == '0x') {
      throw const SigningCancelledException();
    }
    await appStore.sessionCache.saveSignature(address, signature);
  }

  Future<String> _fetchSignMessage(String address) async {
    final uri = buildUri(host, signMessagePath, {'address': address});
    final response = await appStore.httpClient
        .get(uri, headers: {'accept': 'application/json'})
        .timeout(_httpTimeout);
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to get sign message. Status: ${response.statusCode} ${response.body}',
      );
    }
    return (jsonDecode(response.body) as Map<String, dynamic>)['message'] as String;
  }

  // Exceptions this method can throw on the BitBox path:
  //   * `BitboxNotConnectedException` — `BitboxCredentials.signPersonalMessage`
  //     aborts up front when the device is disconnected (BLE link dropped).
  //   * `SigningCancelledException` — the user cancels on the device, so the
  //     BitBox swift wrapper returns empty bytes / `'0x'`, normalised here.
  //   * `TimeoutException` — the user never confirms within `_signMessageTimeout`.
  Future<String> getSignature(String message) async {
    final cached = appStore.sessionCache.signature;
    final cachedAddress = appStore.sessionCache.signatureAddress;
    if (cached != null && cachedAddress == walletAddress) {
      return cached;
    }

    // Cache miss — we actually need the private key. Decrypt the mnemonic on
    // demand if the currently loaded wallet is a view-only software wallet.
    // try/finally so a throw from sign / saveSignature can't leave the mnemonic
    // resident for the 60 s idle window — matches the pattern in
    // RealUnitSellPaymentInfoService.confirmPayment and
    // RealUnitRegistrationService.completeRegistration / registerWallet.
    await walletService.ensureCurrentWalletUnlocked();
    try {
      final signature = await wallet.signMessage(message).timeout(_signMessageTimeout);
      if (signature.isEmpty || signature == '0x') {
        throw const SigningCancelledException();
      }
      await appStore.sessionCache.saveSignature(walletAddress, signature);
      return signature;
    } finally {
      await walletService.lockCurrentWallet();
    }
  }

  Future<Map<String, dynamic>> getAuthResponse([bool sendWalletName = true]) async {
    final signature = await getSignature(await getSignMessage());

    final requestBody = jsonEncode(
      sendWalletName
          ? {
              'wallet': walletName,
              'address': walletAddress,
              'signature': signature,
            }
          : {
              'address': walletAddress,
              'signature': signature,
            },
    );

    final uri = buildUri(host, authPath);
    final response = await appStore.httpClient
        .post(uri, headers: {'Content-Type': 'application/json'}, body: requestBody)
        .timeout(_httpTimeout);

    if (response.statusCode == 201) {
      final responseBody = jsonDecode(response.body);
      return responseBody as Map<String, dynamic>;
    } else if (response.statusCode == 403) {
      final responseBody = jsonDecode(response.body);
      final message = responseBody['message'] ?? 'Service unavailable in your country';
      throw Exception(message);
    } else {
      throw Exception('Failed to sign up. Status: ${response.statusCode} ${response.body}');
    }
  }

  // The BitBox-credentials skip introduced in PR #304 is no longer needed:
  // bitbox_flutter v0.0.2 fixed the BLE force-unwrap and dedup hang, the
  // empty-signature guard in `getSignature` covers the cancel/disconnect
  // case gracefully, and the SDK no longer panics on NACK.
  Future<String?> getAuthToken() async {
    if (appStore.sessionCache.authToken == null) {
      await appStore.sessionCache.loadSignature();
      final response = await getAuthResponse();
      appStore.sessionCache.setAuthToken(response['accessToken'] as String);
    }
    return appStore.sessionCache.authToken;
  }

  void invalidateAuthToken() => appStore.sessionCache.clearAuthToken();

  Future<String?> refreshAuthToken() async {
    invalidateAuthToken();
    return getAuthToken();
  }

  Future<http.Response> authenticatedGet(
    Uri uri, {
    Map<String, String> headers = const {},
  }) {
    return _authenticated((token) => appStore.httpClient.get(
          uri,
          headers: {
            ...headers,
            'Authorization': 'Bearer $token',
          },
        ));
  }

  Future<http.Response> authenticatedPut(
    Uri uri, {
    Map<String, String> headers = const {},
    Object? body,
    Encoding? encoding,
  }) {
    return _authenticated((token) => appStore.httpClient.put(
          uri,
          headers: {
            ...headers,
            'Authorization': 'Bearer $token',
          },
          body: body,
          encoding: encoding,
        ));
  }

  Future<http.Response> authenticatedPost(
    Uri uri, {
    Map<String, String> headers = const {},
    Object? body,
    Encoding? encoding,
  }) {
    return _authenticated((token) => appStore.httpClient.post(
          uri,
          headers: {
            ...headers,
            'Authorization': 'Bearer $token',
          },
          body: body,
          encoding: encoding,
        ));
  }

  /// Runs [request] with a Bearer token and retries once on a 401 with a
  /// refreshed token. The caller is responsible for passing the token into
  /// the request headers (so each verb can keep its own `body`/`encoding`
  /// arguments without us re-serialising them here).
  Future<http.Response> _authenticated(
    Future<http.Response> Function(String? token) request,
  ) async {
    var authToken = await getAuthToken();
    var response = await request(authToken);

    if (response.statusCode == 401) {
      authToken = await refreshAuthToken();
      response = await request(authToken);
    }

    return response;
  }
}
