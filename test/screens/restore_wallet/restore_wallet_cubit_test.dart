import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_auth_service.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/packages/wallet/wallet_account.dart';
import 'package:realunit_wallet/screens/restore_wallet/cubit/restore_wallet/restore_wallet_cubit.dart';

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
      final restored = SoftwareWallet(1, 'Obi-Wallet-Kenobi', _testMnemonic);
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

    test('restoreWallet emits a terminal hasError state (not endless loading) when the '
        'service throws (issue #657 P1 B1)', () async {
      when(() => service.restoreWallet(any(), any()))
          .thenAnswer((_) async => throw Exception('persist failed'));
      final cubit = RestoreWalletCubit(service, authService);

      cubit.restoreWallet(_testMnemonic);
      final errorState = await cubit.stream
          .firstWhere((s) => s.hasError)
          .timeout(const Duration(seconds: 1));

      // No permanent spinner: loading cleared, error surfaced, no wallet.
      expect(errorState.hasError, isTrue);
      expect(errorState.isLoading, isFalse);
      expect(errorState.wallet, isNull);
    });

    test('restoreWallet recovers on retry after a failure', () async {
      final restored = SoftwareWallet(1, 'W', _testMnemonic);
      var attempts = 0;
      when(() => service.restoreWallet(any(), any())).thenAnswer((_) async {
        attempts++;
        if (attempts == 1) throw Exception('transient');
        return restored;
      });
      final cubit = RestoreWalletCubit(service, authService);

      cubit.restoreWallet(_testMnemonic);
      await cubit.stream.firstWhere((s) => s.hasError);

      // Retry: the same entry point is called again and now succeeds.
      cubit.restoreWallet(_testMnemonic);
      await cubit.stream.firstWhere((s) => s.wallet != null);

      expect(cubit.state.wallet, same(restored));
      expect(cubit.state.hasError, isFalse);
    });

    test('restoreWallet emits an interim isLoading=true state', () async {
      final restored = SoftwareWallet(1, 'W', _testMnemonic);
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
