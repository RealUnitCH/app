import 'dart:convert';

import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_auth_service.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/bank_account/dto/bank_account_dto.dart';

class DfxBankAccountService extends DFXAuthService {
  static const _bankAccountPath = 'v1/bankAccount';

  DfxBankAccountService(super.appStore, super.walletService);

  Future<List<BankAccountDto>> getBankAccounts() async {
    final uri = buildUri(host, _bankAccountPath);
    final response = await authenticatedGet(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException.fromJson(errorJson, httpStatusCode: response.statusCode);
    }

    final List<dynamic> jsonList = jsonDecode(response.body);
    final bankAccounts = jsonList.map((json) => BankAccountDto.fromJson(json)).toList();
    return bankAccounts;
  }

  Future<BankAccountDto> createBankAccount(String iban, String? label) async {
    final uri = buildUri(host, _bankAccountPath);
    final response = await authenticatedPost(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'iban': iban,
        if (label != null) 'label': label,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException.fromJson(errorJson, httpStatusCode: response.statusCode);
    }

    return BankAccountDto.fromJson(jsonDecode(response.body));
  }

  Future<BankAccountDto> updateBankAccount({
    required int id,
    String? label,
    bool? isDefault,
    bool? isActive,
  }) async {
    final uri = buildUri(host, '$_bankAccountPath/$id');
    final response = await authenticatedPut(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        if (label != null) 'label': label,
        if (isActive != null) 'active': isActive,
        if (isDefault != null) 'default': isDefault,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException.fromJson(errorJson, httpStatusCode: response.statusCode);
    }

    return BankAccountDto.fromJson(jsonDecode(response.body));
  }
}
