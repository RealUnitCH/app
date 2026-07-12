import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/models/bank_account/bank_account.dart';
import 'package:realunit_wallet/screens/sell/cubits/sell_bank_accounts/sell_bank_accounts_cubit.dart';
import 'package:realunit_wallet/screens/sell/cubits/sell_selected_bank_account/sell_selected_bank_account_cubit.dart';
import 'package:realunit_wallet/screens/sell/widgets/sell_bank_account_selection_page.dart';

import '../../../helper/helper.dart';

class _MockSellBankAccountsCubit extends MockCubit<SellBankAccountsState>
    implements SellBankAccountsCubit {}

class _MockSellSelectedBankAccountCubit extends MockCubit<BankAccount?>
    implements SellSelectedBankAccountCubit {}

void main() {
  late _MockSellBankAccountsCubit accountsCubit;
  late _MockSellSelectedBankAccountCubit selectedCubit;

  setUp(() {
    accountsCubit = _MockSellBankAccountsCubit();
    selectedCubit = _MockSellSelectedBankAccountCubit();
    when(() => accountsCubit.state).thenReturn(const SellBankAccountsInitial());
    when(() => selectedCubit.state).thenReturn(null);
  });

  Widget buildSubject() => MultiBlocProvider(
        providers: [
          BlocProvider<SellBankAccountsCubit>.value(value: accountsCubit),
          BlocProvider<SellSelectedBankAccountCubit>.value(value: selectedCubit),
        ],
        child: const SellBankAccountSelectionPage(),
      );

  group('$SellBankAccountSelectionPage', () {
    goldenTest(
      'empty list, add bank account button visible',
      fileName: 'sell_bank_account_selection_page_default',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      builder: () => wrapForGolden(buildSubject()),
    );
  });
}
