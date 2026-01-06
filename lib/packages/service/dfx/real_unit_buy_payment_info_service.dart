import 'dart:convert';

import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/buy_payment_info.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/dto/real_unit_buy_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/dto/real_unit_buy_payment_info_dto.dart';
import 'package:realunit_wallet/styles/currency.dart';

class RealUnitBuyPaymentInfoService {
  static const _buyPaymentInfoPath = "/v1/realunit/buy";

  String get _host => _appStore.apiConfig.apiHost;

  final AppStore _appStore;

  RealUnitBuyPaymentInfoService(AppStore appStore) : _appStore = appStore;

  Future<BuyPaymentInfo> getPaymentInfo(int amount, {Currency currency = Currency.chf}) async {
    final buyDto = RealUnitBuyDto(amount: amount, currency: currency);

    final authToken = _appStore.dfxAuthToken;
    final uri = Uri.https(_host, _buyPaymentInfoPath);
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
      );
    } else if (response.statusCode == 403) {
      final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException.fromJson(errorJson);
    } else {
      throw Exception('Unexpected status code: ${response.statusCode}');
    }
  }

  Future<void> confirmPayment(int id) async {
    final authToken = _appStore.dfxAuthToken;
    final uri = Uri.https(_host, '/v1/buy/paymentInfos/$id/confirm');

    final response = await _appStore.httpClient.put(
      uri,
      headers: {
        'Authorization': 'Bearer $authToken',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to confirm payment: ${response.statusCode}');
    }
  }
}
