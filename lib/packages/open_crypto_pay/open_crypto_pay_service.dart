import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart';
import 'package:realunit_wallet/models/asset.dart';
import 'package:realunit_wallet/models/blockchain.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/open_crypto_pay/exceptions.dart';
import 'package:realunit_wallet/packages/open_crypto_pay/models.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';
import 'package:realunit_wallet/packages/wallet/payment_uri.dart';

class OpenCryptoPayService {
  final Client _httpClient = Client();

  Future<String> commitOpenCryptoPayRequest(
    String txHex, {
    required OpenCryptoPayRequest request,
    required Asset asset,
  }) async {
    final uri = Uri.parse(request.callbackUrl.replaceAll('/cb/', '/tx/'));

    final queryParams = Map.of(uri.queryParameters);

    queryParams['quote'] = request.quote;
    queryParams['asset'] = asset.name;
    queryParams['method'] = _getMethod(asset);
    queryParams['hex'] = txHex;

    final response = await _httpClient.get(buildUri(uri.authority, uri.path, queryParams));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map;

      if (body.keys.contains('txId')) return body['txId'] as String;
      throw OpenCryptoPayException(body.toString());
    }
    throw OpenCryptoPayException('Unexpected status code ${response.statusCode} ${response.body}');
  }

  Future<void> cancelOpenCryptoPayRequest(OpenCryptoPayRequest request) async {
    final uri = Uri.parse(request.callbackUrl.replaceAll('/cb/', '/cancel/'));

    developer.log('Canceling Open CryptoPay Invoice ${request.quote}',
        name: 'OpenCryptoPayService.cancelOpenCryptoPayRequest', level: 800);
    await _httpClient.delete(uri);
  }

  Future<ERC681URI> getOpenCryptoPayAddress(OpenCryptoPayRequest request, Asset asset) async {
    final uri = Uri.parse(request.callbackUrl);
    final queryParams = Map.of(uri.queryParameters);

    queryParams['quote'] = request.quote;
    if ([dEUROBaseAsset.id, dEUROOptimismAsset.id, dEUROArbitrumAsset.id, dEUROPolygonAsset.id]
        .contains(asset.id)) {
      queryParams['asset'] = dEUROAsset.name;
    } else {
      queryParams['asset'] = asset.name;
    }
    queryParams['method'] = _getMethod(asset);

    final response = await _httpClient.get(buildUri(uri.authority, uri.path, queryParams));

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body) as Map;

      for (final key in ['expiryDate', 'uri']) {
        if (!responseBody.keys.contains(key)) {
          throw OpenCryptoPayNotSupportedException(uri.authority);
        }
      }

      return ERC681URI.fromString(responseBody['uri'] as String);
    } else {
      developer.log('Error occurred',
          error: response.body, name: 'OpenCryptoPayService.getOpenCryptoPayAddress', level: 900);
      throw OpenCryptoPayException(
          'Failed to create Open CryptoPay Request. Status: ${response.statusCode} ${response.body}');
    }
  }

  String _getMethod(Asset asset) => Blockchain.getFromChainId(asset.chainId).name;
}

