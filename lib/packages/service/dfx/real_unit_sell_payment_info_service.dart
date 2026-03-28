import 'dart:convert';

import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/eip7702/eip7702_confirm_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/real_unit_sell_confirm_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/real_unit_sell_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/real_unit_sell_payment_info_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/sell_payment_info.dart';
import 'package:realunit_wallet/packages/wallet/eip712_signer.dart';
import 'package:realunit_wallet/packages/wallet/eip7702_signer.dart';
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
    final uri = buildUri(_host, _sellPaymentInfoPath);
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
        amount: responseDto.amount.toInt(),
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
    final credentials = _appStore.wallet.currentAccount.primaryAddress;
    final delegationSignature = await Eip712Signer.signDelegation(
      credentials: credentials,
      eip7702Data: paymentInfo.eip7702,
    );
    final authorizationSignature = Eip7702Signer.signAuthorization(
      credentials: credentials,
      eip7702Data: paymentInfo.eip7702,
    );
    final sellConfirmDto = RealUnitSellConfirmDto(
        eip7702ConfirmDto: Eip7702ConfirmDto(
            delegation: Eip7702DelegationDto(
              delegate: paymentInfo.eip7702.relayerAddress,
              delegator: paymentInfo.eip7702.message.delegator,
              authority: paymentInfo.eip7702.message.authority,
              salt: '${paymentInfo.eip7702.message.salt}',
              signature: delegationSignature,
            ),
            authorization: Eip7702AuthorizationDto(
              chainId: paymentInfo.eip7702.domain.chainId,
              address: paymentInfo.eip7702.delegatorAddress,
              nonce: paymentInfo.eip7702.userNonce,
              r: '0x${authorizationSignature.r.toRadixString(16)}',
              s: '0x${authorizationSignature.s.toRadixString(16)}',
              yParity: authorizationSignature.yParity,
            )));

    final authToken = _appStore.dfxAuthToken;
    final uri = buildUri(_host, _confirmPaymentPath(paymentInfo.id));
    final response = await _appStore.httpClient.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode(sellConfirmDto),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to confirm payment: ${response.statusCode}');
    }
  }
}
