import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_auth_service.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/packages/wallet/wallet_account.dart';
import 'package:realunit_wallet/screens/restore_wallet/cubit/restore_wallet/restore_wallet_cubit.dart';

import '../../test_utils/fake_wallet_isolate.dart';

class _MockWalletService extends Mock implements WalletService {}

class _MockAuthService extends Mock implements DFXAuthService {}

class _FakeWalletAccount extends Fake implements AWalletAccount {}

const _testMnemonic =
    'test test test test test test test test test test test junk';

void main() {
  late _MockWalletService service;
  late _MockAuthService authService;

  setUpAll(() {
    registerFallbackValue(_FakeWalletAccount());
  });

  setUp(() {
    service = _MockWalletService();
    authService = _MockAuthService();
    when(() => authService.ensureSignatureFor(any())).thenAnswer((_) async {});
  });

  group('$RestoreWalletCubit', () {
    test('initial state is not loading and has no wallet', () {
      final cubit = RestoreWalletCubit(service, authService);

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.wallet, isNull);
    });

    test('restoreWallet normalises whitespace before delegating to the service', () async {
      final restored = SoftwareWallet(
        1,
        'Obi-Wallet-Kenobi',
        '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
        FakeWalletIsolate(),
      );
      when(() => service.restoreWallet(any(), any())).thenAnswer((_) async => restored);
      final cubit = RestoreWalletCubit(service, authService);

      // Caller pastes a seed with leading/trailing/inner extra spaces.
      cubit.restoreWallet('  test test  test test  test test  test test  test test  test junk ');
      await cubit.stream.firstWhere((s) => s.wallet != null);

      // Restore service receives the canonicalised, single-spaced mnemonic.
      verify(() => service.restoreWallet('Obi-Wallet-Kenobi', _testMnemonic)).called(1);
      verify(() => authService.ensureSignatureFor(restored.currentAccount)).called(1);
      expect(cubit.state.wallet, same(restored));
      expect(cubit.state.isLoading, isFalse);
    });

    test('restoreWallet emits an interim isLoading=true state', () async {
      final restored = SoftwareWallet(
        1,
        'W',
        '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
        FakeWalletIsolate(),
      );
      when(() => service.restoreWallet(any(), any())).thenAnswer((_) async => restored);
      final cubit = RestoreWalletCubit(service, authService);
      final loadingFuture = cubit.stream.firstWhere((s) => s.isLoading);

      cubit.restoreWallet(_testMnemonic);
      await loadingFuture.timeout(const Duration(seconds: 1));

      // The loading state was observed.
      await cubit.stream.firstWhere((s) => s.wallet != null);
      expect(cubit.state.wallet, same(restored));
    });
  });
}
