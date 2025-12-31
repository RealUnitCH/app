import 'dart:convert';
import 'dart:developer' as developer;

import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/dfx_buy_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/dfx_buy_payment_info.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/dfx_buy_payment_info_dto.dart';
import 'package:realunit_wallet/styles/currency.dart';

class DfxBuyPaymentInfoService {
  static const _baseUrl = "dev.api.dfx.swiss";
  static const _buyPaymentInfoPath = "/v1/realunit/paymentInfo";

  final AppStore appStore;

  DfxBuyPaymentInfoService(this.appStore);

  Future<DfxBuyPaymentInfo> getPaymentInfo(int amount, {Currency currency = Currency.chf}) async {
    try {
      final requestDto = DfxBuyDto(amount: amount, currency: currency);

      final authToken = appStore.dfxAuthToken;
      final uri = Uri.https(_baseUrl, _buyPaymentInfoPath);
      final response = await appStore.httpClient.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(requestDto.toJson()),
      );

      final json = jsonDecode(response.body);
      final dto = DfxBuyPaymentInfoDto.fromJson(json);

      return DfxBuyPaymentInfo(
        iban: dto.iban,
        bic: dto.bic,
        name: dto.name,
        street: dto.street,
        number: dto.number,
        zip: dto.zip,
        city: dto.city,
        country: dto.country,
        currency: dto.currency,
      );
    } catch (e) {
      developer.log(e.toString());
      throw Exception('Buy Payment Info Request failed: $e');
    }
  }
}
