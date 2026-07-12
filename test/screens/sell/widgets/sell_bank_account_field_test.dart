import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/models/bank_account/bank_account.dart';
import 'package:realunit_wallet/screens/sell/cubits/sell_bank_accounts/sell_bank_accounts_cubit.dart';
import 'package:realunit_wallet/screens/sell/cubits/sell_selected_bank_account/sell_selected_bank_account_cubit.dart';
import 'package:realunit_wallet/screens/sell/widgets/sell_bank_account_field.dart';

import '../../../helper/helper.dart';

class _MockSellBankAccountsCubit extends MockCubit<SellBankAccountsState>
    implements SellBankAccountsCubit {}

class _MockSellSelectedBankAccountCubit extends MockCubit<BankAccount?>
    implements SellSelectedBankAccountCubit {}

void main() {
  late _MockSellBankAccountsCubit accountsCubit;
  late _MockSellSelectedBankAccountCubit selectedCubit;

  const accountActiveNonDefault1 = BankAccount(
    id: 1,
    iban: 'CH0000000000000000001',
    isActive: true,
  );
  const accountActiveNonDefault2 = BankAccount(
    id: 2,
    iban: 'CH0000000000000000002',
    isActive: true,
  );
  const accountDefault = BankAccount(
    id: 3,
    iban: 'CH0000000000000000003',
    isActive: true,
    isDefault: true,
  );
  const accountDefaultSecond = BankAccount(
    id: 5,
    iban: 'CH0000000000000000005',
    isActive: true,
    isDefault: true,
  );
  const accountInactive = BankAccount(
    id: 4,
    iban: 'CH0000000000000000004',
  );
  const accountDefaultButInactive = BankAccount(
    id: 6,
    iban: 'CH0000000000000000006',
    isDefault: true,
  );

  setUpAll(() {
    registerFallbackValue(accountActiveNonDefault1);
  });

  setUp(() {
    accountsCubit = _MockSellBankAccountsCubit();
    selectedCubit = _MockSellSelectedBankAccountCubit();
    when(() => selectedCubit.state).thenReturn(null);
  });

  Future<void> pumpView(WidgetTester tester) => tester.pumpApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<SellBankAccountsCubit>.value(value: accountsCubit),
        BlocProvider<SellSelectedBankAccountCubit>.value(value: selectedCubit),
      ],
      child: const Scaffold(
        body: SingleChildScrollView(child: BankAccountFieldView()),
      ),
    ),
  );

  group('$BankAccountFieldView auto-selection precedence', () {
    testWidgets('prefers the default account when one is flagged', (tester) async {
      whenListen(
        accountsCubit,
        Stream.fromIterable(const [
          SellBankAccountsInitial(),
          SellBankAccountsSuccess([
            accountActiveNonDefault1,
            accountDefault,
            accountActiveNonDefault2,
          ]),
        ]),
        initialState: const SellBankAccountsInitial(),
      );

      await pumpView(tester);
      await tester.pump();

      verify(() => selectedCubit.selectBankAccount(accountDefault)).called(1);
    });

    testWidgets(
      'selects null when no default is flagged (no active-fallback heuristic)',
      (tester) async {
        // Strict mode per "Keine Fallbacks" rule: if the backend doesn't tag a
        // default we do NOT silently pick "the last active account". The user
        // has to choose explicitly.
        whenListen(
          accountsCubit,
          Stream.fromIterable(const [
            SellBankAccountsInitial(),
            SellBankAccountsSuccess([accountActiveNonDefault1, accountActiveNonDefault2]),
          ]),
          initialState: const SellBankAccountsInitial(),
        );

        await pumpView(tester);
        await tester.pump();

        verify(() => selectedCubit.selectBankAccount(null)).called(1);
      },
    );

    testWidgets(
      'selects null when accounts exist but none are default or active',
      (tester) async {
        whenListen(
          accountsCubit,
          Stream.fromIterable(const [
            SellBankAccountsInitial(),
            SellBankAccountsSuccess([accountInactive]),
          ]),
          initialState: const SellBankAccountsInitial(),
        );

        await pumpView(tester);
        await tester.pump();

        verify(() => selectedCubit.selectBankAccount(null)).called(1);
      },
    );

    testWidgets(
      'selects null when the only default account is inactive',
      (tester) async {
        // Threat model: backend bug could ship `default: true, active: false`.
        // We must not auto-select such an account — `sell_button.dart` only
        // null-checks the selection, so an inactive default would slip through.
        whenListen(
          accountsCubit,
          Stream.fromIterable(const [
            SellBankAccountsInitial(),
            SellBankAccountsSuccess([
              accountActiveNonDefault1,
              accountDefaultButInactive,
            ]),
          ]),
          initialState: const SellBankAccountsInitial(),
        );

        await pumpView(tester);
        await tester.pump();

        verify(() => selectedCubit.selectBankAccount(null)).called(1);
      },
    );

    testWidgets(
      'picks the first default when multiple defaults are flagged',
      (tester) async {
        // Plan W1.2 acceptance: "If multiple defaults (shouldn't happen) →
        // first wins." Pins `firstWhereOrNull` ordering so a future switch to
        // `lastWhereOrNull` (or any reverse iteration) is caught by CI. The
        // `developer.log` warning emitted in this case is observable in dev
        // tooling but not asserted here (dart:developer has no mockable
        // surface).
        whenListen(
          accountsCubit,
          Stream.fromIterable(const [
            SellBankAccountsInitial(),
            SellBankAccountsSuccess([
              accountActiveNonDefault1,
              accountDefault,
              accountDefaultSecond,
            ]),
          ]),
          initialState: const SellBankAccountsInitial(),
        );

        await pumpView(tester);
        await tester.pump();

        verify(() => selectedCubit.selectBankAccount(accountDefault)).called(1);
        verifyNever(() => selectedCubit.selectBankAccount(accountDefaultSecond));
      },
    );

    testWidgets('does nothing when accounts list stays empty', (tester) async {
      whenListen(
        accountsCubit,
        Stream.fromIterable(const [
          SellBankAccountsInitial(),
          SellBankAccountsLoadFailure(),
        ]),
        initialState: const SellBankAccountsInitial(),
      );

      await pumpView(tester);
      await tester.pump();

      verifyNever(() => selectedCubit.selectBankAccount(any()));
    });
  });
}
