import 'dart:convert';

import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/wallet/wallet_account.dart';

abstract class DFXAuthService {
  static const walletName = 'RealUnit';

  final String signMessagePath = '/v1/auth/signMessage';
  final String authPath = '/v1/auth';
  final AppStore appStore;

  DFXAuthService(this.appStore);

  String get host => appStore.apiConfig.apiHost;

  AWalletAccount get wallet;

  String get walletAddress;

  Future<String> getSignMessage() async {
    final uri = buildUri(host, signMessagePath, {'address': walletAddress});

    final response = await appStore.httpClient.get(uri, headers: {'accept': 'application/json'});

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      return responseBody['message'] as String;
    } else {
      throw Exception(
          'Failed to get sign message. Status: ${response.statusCode} ${response.body}');
    }
  }

  Future<String> getSignature(String message) async {
    // Use cached signature if available for this address
    final cached = appStore.cachedDfxSignature;
    final cachedAddress = appStore.cachedDfxSignatureAddress;
    if (cached != null && cachedAddress == walletAddress) {
      return cached;
    }

    // Sign with wallet (requires hardware wallet connection for BitBox)
    final signature = await wallet.signMessage(message);

    // Persist signature for future use without hardware wallet
    await appStore.saveDfxSignature(walletAddress, signature);

    return signature;
  }

  Future<Map<String, dynamic>> getAuthResponse([bool sendWalletName = true]) async {
    final signature = await getSignature(await getSignMessage());

    final requestBody = jsonEncode(sendWalletName
        ? {
            'wallet': walletName,
            'address': walletAddress,
            'signature': signature,
          }
        : {
            'address': walletAddress,
            'signature': signature,
          });

    final uri = buildUri(host, authPath);
    final response = await appStore.httpClient.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: requestBody,
    );

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

  Future<String?> getAuthToken() async {
    if (appStore.dfxAuthToken == null) {
      await appStore.loadCachedDfxSignature();
      final response = await getAuthResponse();
      appStore.dfxAuthToken = response['accessToken'] as String;
    }
    return appStore.dfxAuthToken;
  }

  void invalidateAuthToken() => appStore.dfxAuthToken = null;

  Future<String?> refreshAuthToken() async {
    invalidateAuthToken();
    return getAuthToken();
  }
}
