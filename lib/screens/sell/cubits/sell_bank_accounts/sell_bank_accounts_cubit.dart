import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_bank_account_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/bank_account/bank_account.dart';

part 'sell_bank_accounts_state.dart';

class SellBankAccountsCubit extends Cubit<SellBankAccountsState> {
  final DfxBankAccountService _dfxBankAccountService;

  SellBankAccountsCubit(
    DfxBankAccountService bankAccountService,
  ) : _dfxBankAccountService = bankAccountService,
      super(const SellBankAccountsInitial()) {
    _loadBankAccounts();
  }

  Future<void> add({required String iban, String? label}) async {
    try {
      emit(SellBankAccountsLoading(state.accounts));

      await _dfxBankAccountService.createBankAccount(iban, label);
      await _loadBankAccounts();
    } catch (e) {
      developer.log(e.toString());
      emit(SellBankAccountsAddFailure(state.accounts, e.toString()));
    }
  }

  Future<void> deactivate({required BankAccount bankAccount}) async {
    try {
      emit(SellBankAccountsLoading(state.accounts));

      await _dfxBankAccountService.updateBankAccount(
        id: bankAccount.id,
        isActive: false,
      );
      await _loadBankAccounts();
    } catch (e) {
      developer.log(e.toString());
      emit(SellBankAccountsUpdateFailure(state.accounts));
    }
  }

  Future<void> _loadBankAccounts() async {
    try {
      emit(SellBankAccountsLoading(state.accounts));

      final dto = await _dfxBankAccountService.getBankAccounts();
      final bankAccounts = dto
          .map(
            (bankAccount) => BankAccount(
              id: bankAccount.id,
              iban: bankAccount.iban,
              name: bankAccount.label,
              isActive: bankAccount.isActive,
              isDefault: bankAccount.isDefault,
            ),
          )
          .toList();
      emit(SellBankAccountsSuccess(bankAccounts));
    } catch (e) {
      developer.log(e.toString());
      emit(const SellBankAccountsLoadFailure());
    }
  }
}
