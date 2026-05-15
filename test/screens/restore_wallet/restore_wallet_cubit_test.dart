import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/screens/restore_wallet/cubit/restore_wallet/restore_wallet_cubit.dart';

class _MockWalletService extends Mock implements WalletService {}

const _testMnemonic =
    'test test test test test test test test test test test junk';

void main() {
  late _MockWalletService service;

  setUp(() {
    service = _MockWalletService();
  });

  group('$RestoreWalletCubit', () {
    test('initial state is not loading and has no wallet', () {
      final cubit = RestoreWalletCubit(service);

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.wallet, isNull);
    });

    test('restoreWallet normalises whitespace before delegating to the service', () async {
      final restored = SoftwareWallet(1, 'Obi-Wallet-Kenobi', _testMnemonic);
      when(() => service.restoreWallet(any(), any())).thenAnswer((_) async => restored);
      final cubit = RestoreWalletCubit(service);

      // Caller pastes a seed with leading/trailing/inner extra spaces.
      cubit.restoreWallet('  test test  test test  test test  test test  test test  test junk ');
      await cubit.stream.firstWhere((s) => s.wallet != null);

      // Restore service receives the canonicalised, single-spaced mnemonic.
      verify(() => service.restoreWallet('Obi-Wallet-Kenobi', _testMnemonic)).called(1);
      expect(cubit.state.wallet, same(restored));
      expect(cubit.state.isLoading, isFalse);
    });

    test('restoreWallet emits an interim isLoading=true state', () async {
      final restored = SoftwareWallet(1, 'W', _testMnemonic);
      when(() => service.restoreWallet(any(), any())).thenAnswer((_) async => restored);
      final cubit = RestoreWalletCubit(service);
      final loadingFuture = cubit.stream.firstWhere((s) => s.isLoading);

      cubit.restoreWallet(_testMnemonic);
      await loadingFuture.timeout(const Duration(seconds: 1));

      // The loading state was observed.
      await cubit.stream.firstWhere((s) => s.wallet != null);
      expect(cubit.state.wallet, same(restored));
    });
  });
}
