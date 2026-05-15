import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/service/dfx/models/bank_account/bank_account.dart';
import 'package:realunit_wallet/screens/sell/cubits/sell_selected_bank_account/sell_selected_bank_account_cubit.dart';

const _account = BankAccount(id: 1, iban: 'CH56 0483 5012 3456 7800 9', isActive: true);

void main() {
  group('$SellSelectedBankAccountCubit', () {
    test('initial state is null', () {
      expect(SellSelectedBankAccountCubit().state, isNull);
    });

    blocTest<SellSelectedBankAccountCubit, BankAccount?>(
      'selectBankAccount emits the provided account',
      build: SellSelectedBankAccountCubit.new,
      act: (cubit) => cubit.selectBankAccount(_account),
      expect: () => [_account],
    );

    blocTest<SellSelectedBankAccountCubit, BankAccount?>(
      'selectBankAccount(null) clears the selection',
      build: SellSelectedBankAccountCubit.new,
      seed: () => _account,
      act: (cubit) => cubit.selectBankAccount(null),
      expect: () => [null],
    );
  });
}
