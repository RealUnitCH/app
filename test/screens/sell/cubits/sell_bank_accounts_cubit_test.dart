import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_bank_account_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/bank_account/dto/bank_account_dto.dart';
import 'package:realunit_wallet/screens/sell/cubits/sell_bank_accounts/sell_bank_accounts_cubit.dart';

class _MockBankAccountService extends Mock implements DfxBankAccountService {}

BankAccountDto _dto({int id = 1, String? label, bool isActive = true}) =>
    BankAccountDto(
      id: id,
      iban: 'CH56 0483 5012 3456 78$id',
      label: label,
      isActive: isActive,
      isDefault: false,
    );

void main() {
  late _MockBankAccountService service;

  setUp(() {
    service = _MockBankAccountService();
  });

  group('$SellBankAccountsCubit', () {
    test('reaches Success with the mapped accounts on construction', () async {
      when(() => service.getBankAccounts())
          .thenAnswer((_) async => [_dto(id: 1, label: 'Main'), _dto(id: 2)]);

      final cubit = SellBankAccountsCubit(service);
      await cubit.stream.firstWhere((s) => s is SellBankAccountsSuccess);

      final success = cubit.state as SellBankAccountsSuccess;
      expect(success.accounts.map((a) => a.id), [1, 2]);
      expect(success.accounts.first.name, 'Main');
    });

    test('reaches LoadFailure when getBankAccounts throws', () async {
      when(() => service.getBankAccounts())
          .thenAnswer((_) async => throw Exception('boom'));

      final cubit = SellBankAccountsCubit(service);
      await cubit.stream.firstWhere((s) => s is SellBankAccountsLoadFailure);

      expect(cubit.state, isA<SellBankAccountsLoadFailure>());
    });

    test('add() calls createBankAccount and re-fetches the list', () async {
      var calls = 0;
      when(() => service.getBankAccounts()).thenAnswer((_) async {
        calls++;
        if (calls == 1) return [_dto(id: 1)];
        return [_dto(id: 1), _dto(id: 2, label: 'Added')];
      });
      when(() => service.createBankAccount(any(), any()))
          .thenAnswer((_) async => _dto(id: 2, label: 'Added'));

      final cubit = SellBankAccountsCubit(service);
      await cubit.stream.firstWhere((s) => s is SellBankAccountsSuccess);

      await cubit.add(iban: 'CH99', label: 'Added');

      final success = cubit.state as SellBankAccountsSuccess;
      expect(success.accounts.map((a) => a.id), [1, 2]);
      verify(() => service.createBankAccount('CH99', 'Added')).called(1);
    });

    test('add() emits AddFailure on createBankAccount error and keeps prior accounts', () async {
      when(() => service.getBankAccounts()).thenAnswer((_) async => [_dto(id: 1)]);
      when(() => service.createBankAccount(any(), any()))
          .thenAnswer((_) async => throw Exception('invalid iban'));

      final cubit = SellBankAccountsCubit(service);
      await cubit.stream.firstWhere((s) => s is SellBankAccountsSuccess);

      await cubit.add(iban: 'NOPE');

      expect(cubit.state, isA<SellBankAccountsAddFailure>());
      expect((cubit.state as SellBankAccountsAddFailure).message, contains('invalid iban'));
      expect(cubit.state.accounts, hasLength(1));
    });

    test('deactivate() calls updateBankAccount(isActive=false) and re-fetches', () async {
      var calls = 0;
      when(() => service.getBankAccounts()).thenAnswer((_) async {
        calls++;
        if (calls == 1) return [_dto(id: 1, isActive: true)];
        return [_dto(id: 1, isActive: false)];
      });
      when(() => service.updateBankAccount(
            id: any(named: 'id'),
            isActive: any(named: 'isActive'),
          )).thenAnswer((_) async => _dto(id: 1, isActive: false));

      final cubit = SellBankAccountsCubit(service);
      await cubit.stream.firstWhere((s) => s is SellBankAccountsSuccess);

      final target = (cubit.state as SellBankAccountsSuccess).accounts.first;
      await cubit.deactivate(bankAccount: target);

      verify(() => service.updateBankAccount(id: 1, isActive: false)).called(1);
      final success = cubit.state as SellBankAccountsSuccess;
      expect(success.accounts.first.isActive, isFalse);
    });

    test('deactivate() emits UpdateFailure on updateBankAccount error', () async {
      when(() => service.getBankAccounts()).thenAnswer((_) async => [_dto(id: 1)]);
      when(() => service.updateBankAccount(
            id: any(named: 'id'),
            isActive: any(named: 'isActive'),
          )).thenAnswer((_) async => throw Exception('500'));

      final cubit = SellBankAccountsCubit(service);
      await cubit.stream.firstWhere((s) => s is SellBankAccountsSuccess);

      final target = (cubit.state as SellBankAccountsSuccess).accounts.first;
      await cubit.deactivate(bankAccount: target);

      expect(cubit.state, isA<SellBankAccountsUpdateFailure>());
      expect(cubit.state.accounts, hasLength(1));
    });
  });
}
