import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart';
import 'package:realunit_wallet/models/asset.dart';
import 'package:realunit_wallet/models/blockchain.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/open_crypto_pay/exceptions.dart';
import 'package:realunit_wallet/packages/open_crypto_pay/lnurl.dart';
import 'package:realunit_wallet/packages/open_crypto_pay/models.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';
import 'package:realunit_wallet/packages/wallet/payment_uri.dart';

class OpenCryptoPayService {
  static bool isOpenCryptoPayQR(String value) =>
      value.toLowerCase().contains('lightning=lnurl') || value.toLowerCase().startsWith('lnurl');

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

  Future<OpenCryptoPayRequest> getOpenCryptoPayInvoice(String lnUrl) async {
    if (lnUrl.toLowerCase().startsWith('http')) {
      final uri = Uri.parse(lnUrl);
      final params = uri.queryParameters;
      if (!params.containsKey('lightning')) {
        throw OpenCryptoPayNotSupportedException(uri.authority);
      }

      lnUrl = params['lightning'] as String;
    }
    final url = decodeLNURL(lnUrl);
    final params = await _getOpenCryptoPayParams(url);

    return OpenCryptoPayRequest(
      receiverName: params.$1.displayName ?? 'Unknown',
      expiration: params.$1.expiration,
      callbackUrl: params.$1.callbackUrl,
      amount: params.$1.amount,
      amountSymbol: params.$1.amountSymbol,
      quote: params.$1.id,
      methods: params.$2,
    );
  }

  Future<(_OpenCryptoPayQuote, Map<String, List<OpenCryptoPayQuoteAsset>>)> _getOpenCryptoPayParams(
      Uri uri) async {
    final response = await _httpClient.get(uri);

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body) as Map;

      for (final key in ['callback', 'transferAmounts', 'quote']) {
        if (!responseBody.keys.contains(key)) {
          throw OpenCryptoPayNotSupportedException(uri.authority);
        }
      }

      final methods = <String, List<OpenCryptoPayQuoteAsset>>{};
      for (final transferAmountRaw in responseBody['transferAmounts'] as List) {
        final transferAmount = transferAmountRaw as Map;
        final method = transferAmount['method'] as String;
        final minFee = transferAmount['minFee'] as num;
        methods[method] = [];
        for (final assetJson in transferAmount['assets'] as List) {
          final asset =
              OpenCryptoPayQuoteAsset.fromJson(assetJson as Map<String, dynamic>, minFee.toInt());
          methods[method]?.add(asset);
        }
      }

      final quote = _OpenCryptoPayQuote.fromJson(
          responseBody['callback'] as String,
          responseBody['displayName'] as String?,
          (responseBody['requestedAmount']['amount'] as num).toString(),
          responseBody['requestedAmount']['asset'] as String,
          responseBody['quote'] as Map<String, dynamic>);

      return (quote, methods);
    } else {
      throw OpenCryptoPayException(
          'Failed to get Open CryptoPay Request. Status: ${response.statusCode} ${response.body}');
    }
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

class _OpenCryptoPayQuote {
  final String callbackUrl;
  final String? displayName;
  final String id;
  final DateTime expiration;
  final String amount;
  final String amountSymbol;

  _OpenCryptoPayQuote(
      this.callbackUrl, this.displayName, this.id, this.expiration, this.amount, this.amountSymbol);

  _OpenCryptoPayQuote.fromJson(
      this.callbackUrl, this.displayName, this.amount, this.amountSymbol, Map<String, dynamic> json)
      : id = json['id'] as String,
        expiration = DateTime.parse(json['expiration'] as String);
}
