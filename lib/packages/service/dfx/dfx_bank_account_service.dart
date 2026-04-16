import 'dart:convert';

import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/models/bank_account/dto/bank_account_dto.dart';

class DfxBankAccountService {
  static const _bankAccountPath = 'v1/bankAccount';

  String get _host => _appStore.apiConfig.apiHost;

  final AppStore _appStore;

  DfxBankAccountService(AppStore appStore) : _appStore = appStore;

  Future<List<BankAccountDto>> getBankAccounts() async {
    final authToken = _appStore.sessionCache.authToken;

    final uri = buildUri(_host, _bankAccountPath);
    final response = await _appStore.httpClient.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add bank account: ${response.body}');
    }

    final List<dynamic> jsonList = jsonDecode(response.body);
    final bankAccounts = jsonList.map((json) => BankAccountDto.fromJson(json)).toList();
    return bankAccounts;
  }

  Future<BankAccountDto> createBankAccount(String iban, String? label) async {
    final authToken = _appStore.sessionCache.authToken;

    final uri = buildUri(_host, _bankAccountPath);
    final response = await _appStore.httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({
        'iban': iban,
        if (label != null) 'label': label,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add bank account: ${response.body}');
    }

    return BankAccountDto.fromJson(jsonDecode(response.body));
  }

  Future<BankAccountDto> updateBankAccount({
    required int id,
    String? label,
    bool? isDefault,
    bool? isActive,
  }) async {
    final authToken = _appStore.sessionCache.authToken;

    final uri = buildUri(_host, '$_bankAccountPath/$id');
    final response = await _appStore.httpClient.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({
        if (label != null) 'label': label,
        if (isActive != null) 'active': isActive,
        if (isDefault != null) 'default': isDefault,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to update bank account: ${response.body}');
    }

    return BankAccountDto.fromJson(jsonDecode(response.body));
  }
}
