import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/wallet/exceptions/signing_cancelled_exception.dart';
import 'package:realunit_wallet/packages/wallet/wallet_account.dart';

abstract class DFXAuthService {
  static const walletName = 'RealUnit';
  static const _signMessageTimeout = Duration(minutes: 3);
  static const _httpTimeout = Duration(seconds: 20);

  final String signMessagePath = '/v1/auth/signMessage';
  final String authPath = '/v1/auth';
  final AppStore appStore;

  DFXAuthService(this.appStore);

  String get host => appStore.apiConfig.apiHost;

  AWalletAccount get wallet => appStore.wallet.currentAccount;

  String get walletAddress => wallet.primaryAddress.address.hexEip55;

  Future<String> getSignMessage() async {
    final uri = buildUri(host, signMessagePath, {'address': walletAddress});

    final response = await appStore.httpClient
        .get(uri, headers: {'accept': 'application/json'})
        .timeout(_httpTimeout);

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      return responseBody['message'] as String;
    } else {
      throw Exception(
        'Failed to get sign message. Status: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<String> getSignature(String message) async {
    final cached = appStore.sessionCache.signature;
    final cachedAddress = appStore.sessionCache.signatureAddress;
    if (cached != null && cachedAddress == walletAddress) {
      return cached;
    }

    final signature = await wallet.signMessage(message).timeout(_signMessageTimeout);
    if (signature.isEmpty || signature == '0x') {
      throw const SigningCancelledException();
    }
    await appStore.sessionCache.saveSignature(walletAddress, signature);

    return signature;
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
