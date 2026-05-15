import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/screens/create_wallet/bloc/create_wallet_cubit.dart';

class _MockWalletService extends Mock implements WalletService {}

const _testMnemonic =
    'test test test test test test test test test test test junk';

void main() {
  late _MockWalletService service;

  setUp(() {
    service = _MockWalletService();
  });

  group('$CreateWalletCubit', () {
    test('initial state hides the seed and has no wallet', () {
      final cubit = CreateWalletCubit(service);

      expect(cubit.state.hideSeed, isTrue);
      expect(cubit.state.wallet, isNull);
    });

    test('createWallet stores the newly created SoftwareWallet in state', () async {
      final wallet = SoftwareWallet(7, 'Obi-Wallet-Kenobi', _testMnemonic);
      when(() => service.createSeedWallet(any())).thenAnswer((_) async => wallet);

      final cubit = CreateWalletCubit(service);
      cubit.createWallet();
      await cubit.stream.firstWhere((s) => s.wallet != null);

      expect(cubit.state.wallet, same(wallet));
      verify(() => service.createSeedWallet('Obi-Wallet-Kenobi')).called(1);
    });

    blocTest<CreateWalletCubit, CreateWalletState>(
      'toggleShowSeed flips hideSeed between true and false',
      build: () => CreateWalletCubit(service),
      act: (cubit) {
        cubit.toggleShowSeed();
        cubit.toggleShowSeed();
      },
      verify: (cubit) {
        // After two toggles we're back to hidden.
        expect(cubit.state.hideSeed, isTrue);
      },
    );

    test('toggleShowSeed preserves the wallet field', () async {
      final wallet = SoftwareWallet(1, 'W', _testMnemonic);
      when(() => service.createSeedWallet(any())).thenAnswer((_) async => wallet);
      final cubit = CreateWalletCubit(service);
      cubit.createWallet();
      await cubit.stream.firstWhere((s) => s.wallet != null);

      cubit.toggleShowSeed();

      expect(cubit.state.wallet, same(wallet));
      expect(cubit.state.hideSeed, isFalse);
    });
  });
}
