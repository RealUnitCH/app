import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/bank_account.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SellBankAccountsCubit extends Cubit<List<BankAccount>> {
  static const String _storageKey = 'sell_bank_accounts';

  final SharedPreferences _sharedPreferences;

  SellBankAccountsCubit(
    SharedPreferences sharedPreferences,
  )   : _sharedPreferences = sharedPreferences,
        super([]) {
    _loadBankAccounts();
  }

  void addBankAccount({required BankAccount bankAccount}) {
    final updatedList = List<BankAccount>.from(state)..add(bankAccount);
    _sharedPreferences.setString(
        _storageKey, jsonEncode(updatedList.map((a) => a.toJson()).toList()));
    emit(updatedList);
  }

  void _loadBankAccounts() {
    final raw = _sharedPreferences.getString(_storageKey);
    if (raw == null) return;
    final accounts = (jsonDecode(raw) as List<dynamic>)
        .map((e) => BankAccount.fromJson(e as Map<String, dynamic>))
        .toList();
    emit(accounts);
  }
}
