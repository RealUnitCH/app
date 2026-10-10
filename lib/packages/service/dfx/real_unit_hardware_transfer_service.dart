import 'dart:convert';

import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_auth_service.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/broadcast_transaction_request_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/broadcast_transaction_response_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/transfer/dto/real_unit_hardware_transfer_dto.dart';

/// Consumes the BitBox wallet-to-wallet transfer endpoints
/// (`PUT /v1/realunit/transfer/hardware`,
/// `PUT /v1/realunit/transfer/hardware/broadcast`).
///
/// The API builds the unsigned EIP-1559 transaction. The app signs it on the
/// BitBox and returns the signature — it never broadcasts a transaction it
/// built itself.
class RealUnitHardwareTransferService extends DFXAuthService {
  static const _preparePath = '/v1/realunit/transfer/hardware';
  static const _broadcastPath = '/v1/realunit/transfer/hardware/broadcast';

  RealUnitHardwareTransferService(super.appStore, super.walletService);

  Future<RealUnitHardwareTransferPaymentInfoDto> prepareTransfer(
    RealUnitHardwareTransferRequestDto dto,
  ) async {
    final uri = buildUri(host, _preparePath);
    final response = await authenticatedPut(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(dto.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return RealUnitHardwareTransferPaymentInfoDto.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
    throw ApiException.fromJson(errorJson, httpStatusCode: response.statusCode);
  }

  Future<String> broadcastTransfer(BroadcastTransactionRequestDto dto) async {
    final uri = buildUri(host, _broadcastPath);
    final response = await authenticatedPut(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(dto.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException.fromJson(errorJson, httpStatusCode: response.statusCode);
    }

    return BroadcastTransactionResponseDto.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    ).txHash;
  }
}
