import 'dart:convert';

import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/models/dfx_bank_details.dart';

class DfxBankDetailsService {
  final AppStore _appStore;

  DfxBankDetailsService(this._appStore);

  Future<BankDetails> getBankDetails() async {
    final url = Uri.parse("https://dev.api.dfx.swiss/v1/realunit/bank");
    final response = await _appStore.httpClient.get(url);

    if (response.statusCode != 200) {
      throw Exception("Bank details request failed: ${response.body}");
    }

    final json = jsonDecode(response.body);
    return BankDetails.fromJson(json);
  }
}
