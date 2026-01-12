import 'dart:convert';

import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/real_unit_sell_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/real_unit_sell_payment_info_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/sell_payment_info.dart';
import 'package:realunit_wallet/styles/currency.dart';

class RealUnitSellPaymentInfoService {
  static const _sellPaymentInfoPath = '/v1/realunit/sell';
  static String _confirmPaymentPath(int id) => '/v1/realunit/sell/$id/confirm';

  String get _host => _appStore.apiConfig.apiHost;

  final AppStore _appStore;

  RealUnitSellPaymentInfoService(AppStore appStore) : _appStore = appStore;

  Future<SellPaymentInfo> getPaymentInfo(int amount, String iban,
      {Currency currency = Currency.chf}) async {
    final sellDto = RealUnitSellDto(
      amount: amount,
      iban: iban,
      currency: currency,
    );

    final authToken = _appStore.dfxAuthToken;
    final uri = Uri.https(_host, _sellPaymentInfoPath);
    final response = await _appStore.httpClient.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode(sellDto.toJson()),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final responseDto = RealUnitSellPaymentInfoDto.fromJson(json);

      return SellPaymentInfo(
        id: responseDto.id,
        amount: responseDto.amount,
        currency: responseDto.currency,
        beneficiary: responseDto.beneficiary,
        eip7702: responseDto.eip7702,
        estimatedAmount: responseDto.estimatedAmount,
        exchangeRate: responseDto.exchangeRate,
        rate: responseDto.rate,
      );
    } else if (response.statusCode == 403) {
      final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException.fromJson(errorJson);
    } else {
      throw Exception('Unexpected status code: ${response.body}');
    }
  }

  Future<void> confirmPayment(SellPaymentInfo paymentInfo) async {
    final authToken = _appStore.dfxAuthToken;
    final uri = Uri.https(_host, _confirmPaymentPath(paymentInfo.id));

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
