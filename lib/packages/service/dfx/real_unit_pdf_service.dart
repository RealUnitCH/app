import 'dart:convert';

import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/pdf/balance_pdf_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/pdf/multi_receipt_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/pdf/pdf_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/pdf/single_receipt_dto.dart';
import 'package:realunit_wallet/styles/currency.dart';
import 'package:realunit_wallet/styles/language.dart';

class RealUnitPdfService {
  static const _balancePath = '/v1/realunit/balance/pdf';
  static const _transactionsReceiptMultiPath = 'v1/realunit/transactions/receipt/multi';
  static const _transactionsReceiptSinglePath = '/v1/realunit/transactions/receipt/single';

  String get _host => _appStore.apiConfig.apiHost;

  final AppStore _appStore;

  RealUnitPdfService(AppStore appStore) : _appStore = appStore;

  Future<PdfDto> getBalanceReport({
    required DateTime date,
    required Currency currency,
    required Language language,
  }) async {
    final balancePdfDto = BalancePdfDto(
      language: language,
      address: _appStore.primaryAddress,
      currency: currency,
      date: date,
    );

    final authToken = _appStore.sessionCache.authToken;

    final uri = buildUri(_host, _balancePath);
    final response = await _appStore.httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode(balancePdfDto),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException.fromJson(errorJson, httpStatusCode: response.statusCode);
    }

    return PdfDto.fromJson(jsonDecode(response.body));
  }

  Future<PdfDto> getTransactionsReceipt(
    List<String> ids, {
    Currency currency = Currency.chf,
  }) async {
    final authToken = _appStore.sessionCache.authToken;

    final uri = buildUri(_host, _transactionsReceiptMultiPath);
    final response = await _appStore.httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode(MultiReceiptDto(txIds: ids, currency: currency)),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException.fromJson(errorJson, httpStatusCode: response.statusCode);
    }

    return PdfDto.fromJson(jsonDecode(response.body));
  }

  Future<PdfDto> getTransactionReceipt(String id, {Currency currency = Currency.chf}) async {
    final authToken = _appStore.sessionCache.authToken;

    final uri = buildUri(_host, _transactionsReceiptSinglePath);
    final response = await _appStore.httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode(SingleReceiptDto(txId: id, currency: currency)),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException.fromJson(errorJson, httpStatusCode: response.statusCode);
    }

    return PdfDto.fromJson(jsonDecode(response.body));
  }
}
