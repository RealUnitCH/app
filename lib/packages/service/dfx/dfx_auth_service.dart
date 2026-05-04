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

    final signature = await wallet.signMessage(message);
    appStore.sessionCache.saveSignature(walletAddress, signature);

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
    if (appStore.sessionCache.authToken == null) {
      appStore.sessionCache.loadSignature();
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
}
