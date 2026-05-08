import 'dart:convert';

import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/buy/buy_payment_info.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/buy/dto/real_unit_buy_confirm_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/buy/dto/real_unit_buy_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/buy/dto/real_unit_buy_payment_info_dto.dart';
import 'package:realunit_wallet/styles/currency.dart';

class RealUnitBuyPaymentInfoService {
  static const _buyPaymentInfoPath = '/v1/realunit/buy';
  static String _confirmPaymentPath(int id) => '/v1/realunit/buy/$id/confirm';

  String get _host => _appStore.apiConfig.apiHost;

  final AppStore _appStore;

  RealUnitBuyPaymentInfoService(AppStore appStore) : _appStore = appStore;

  Future<BuyPaymentInfo> getPaymentInfo(int amount, {Currency currency = Currency.chf}) async {
    final buyDto = RealUnitBuyDto(amount: amount, currency: currency);

    final authToken = _appStore.sessionCache.authToken;
    final uri = buildUri(_host, _buyPaymentInfoPath);
    final response = await _appStore.httpClient.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode(buyDto.toJson()),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final responseDto = RealUnitBuyPaymentInfoDto.fromJson(json);

      return BuyPaymentInfo(
        id: responseDto.id,
        iban: responseDto.iban,
        bic: responseDto.bic,
        name: responseDto.name,
        street: responseDto.street,
        number: responseDto.number,
        zip: responseDto.zip,
        city: responseDto.city,
        country: responseDto.country,
        currency: responseDto.currency,
        paymentRequest: responseDto.paymentRequest,
        remittanceInfo: responseDto.remittanceInfo,
      );
    } else if (response.statusCode == 403) {
      final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException.fromJson(errorJson, httpStatusCode: response.statusCode);
    } else {
      final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException.fromJson(errorJson, httpStatusCode: response.statusCode);
    }
  }

  Future<String> confirmPayment(int id) async {
    final authToken = _appStore.sessionCache.authToken;
    final uri = buildUri(_host, _confirmPaymentPath(id));

    final response = await _appStore.httpClient.put(
      uri,
      headers: {
        'Authorization': 'Bearer $authToken',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException.fromJson(errorJson, httpStatusCode: response.statusCode);
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final responseDto = RealUnitBuyConfirmDto.fromJson(json);
    return responseDto.reference;
  }
}
