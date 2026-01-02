import 'dart:convert';
import 'dart:developer' as developer;

import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/buy_payment_info.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/dto/real_unit_buy_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/dto/real_unit_buy_payment_info_dto.dart';
import 'package:realunit_wallet/styles/currency.dart';

class RealUnitBuyPaymentInfoService {
  static const _baseUrl = "dev.api.dfx.swiss";
  static const _buyPaymentInfoPath = "/v1/realunit/paymentInfo";

  final AppStore _appStore;

  RealUnitBuyPaymentInfoService(AppStore appStore) : _appStore = appStore;

  Future<BuyPaymentInfo> getPaymentInfo(int amount, {Currency currency = Currency.chf}) async {
    try {
      final buyDto = RealUnitBuyDto(amount: amount, currency: currency);

      final authToken = _appStore.dfxAuthToken;
      final uri = Uri.https(_baseUrl, _buyPaymentInfoPath);
      final response = await _appStore.httpClient.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(buyDto.toJson()),
      );

      final json = jsonDecode(response.body);
      final responseDto = RealUnitBuyPaymentInfoDto.fromJson(json);

      return BuyPaymentInfo(
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
    } catch (e) {
      developer.log(e.toString());
      throw Exception('Buy Payment Info Request failed: $e');
    }
  }
}
