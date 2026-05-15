import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox.dart';
import 'package:realunit_wallet/packages/repository/settings_repository.dart';
import 'package:realunit_wallet/packages/repository/wallet_repository.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/storage/database.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';

class _MockWalletRepository extends Mock implements WalletRepository {}

class _MockSettingsRepository extends Mock implements SettingsRepository {}

class _MockBitboxService extends Mock implements BitboxService {}

const _testMnemonic =
    'test test test test test test test test test test test junk';
const _debugAddress = '0x0000000000000000000000000000000000000001';

WalletInfo _info({
  int id = 1,
  String name = 'Main',
  String seed = '',
  String address = '',
  required WalletType type,
}) =>
    WalletInfo(id: id, name: name, seed: seed, address: address, type: type.index);

void main() {
  late _MockWalletRepository repo;
  late _MockSettingsRepository settings;
  late _MockBitboxService bitbox;
  late WalletService service;

  setUpAll(() {
    // mocktail needs a default for non-primitive types used with `any()`.
    registerFallbackValue(WalletType.software);
  });

  setUp(() {
    repo = _MockWalletRepository();
    settings = _MockSettingsRepository();
    bitbox = _MockBitboxService();
    service = WalletService(bitbox, repo, settings);

    when(() => settings.saveCurrentWalletId(any())).thenAnswer((_) async => true);
    when(() => settings.removeCurrentWalletId()).thenAnswer((_) async => true);
    when(() => repo.deleteWallet(any())).thenAnswer((_) async {});
  });

  group('$WalletService', () {
    group('createSeedWallet', () {
      test('returns a SoftwareWallet with the generated mnemonic persisted', () async {
        when(() => repo.createWallet(any(), any(), any())).thenAnswer((_) async => 42);

        final wallet = await service.createSeedWallet('Main');

        expect(wallet, isA<SoftwareWallet>());
        expect(wallet.id, 42);
        expect(wallet.name, 'Main');
        // Generated mnemonic must be valid bip39.
        expect(service.validateSeed(wallet.seed), isTrue);
        verify(() => repo.createWallet('Main', WalletType.software, wallet.seed)).called(1);
      });

      test('does not set the wallet as current (caller is responsible)', () async {
        when(() => repo.createWallet(any(), any(), any())).thenAnswer((_) async => 42);

        await service.createSeedWallet('Main');

        verifyNever(() => settings.saveCurrentWalletId(any()));
      });
    });

    group('restoreWallet', () {
      test('persists the provided seed and marks the wallet as current', () async {
        when(() => repo.createWallet(any(), any(), any())).thenAnswer((_) async => 7);

        final wallet = await service.restoreWallet('Restored', _testMnemonic);

        expect(wallet.id, 7);
        expect(wallet.name, 'Restored');
        expect(wallet.seed, _testMnemonic);
        verify(() => repo.createWallet('Restored', WalletType.software, _testMnemonic)).called(1);
        verify(() => settings.saveCurrentWalletId(7)).called(1);
      });
    });

    group('createDebugWallet', () {
      test('persists a view wallet and marks it current', () async {
        when(() => repo.createViewWallet(any(), any(), any())).thenAnswer((_) async => 99);

        final wallet = await service.createDebugWallet(_debugAddress);

        expect(wallet, isA<DebugWallet>());
        expect(wallet.id, 99);
        expect(wallet.address, _debugAddress);
        verify(() => repo.createViewWallet('Debug', WalletType.debug, _debugAddress)).called(1);
        verify(() => settings.saveCurrentWalletId(99)).called(1);
      });
    });

    group('getWalletById', () {
      test('returns SoftwareWallet for software type', () async {
        when(() => repo.getWalletById(1)).thenAnswer(
          (_) async => _info(id: 1, name: 'Main', seed: _testMnemonic, type: WalletType.software),
        );

        final wallet = await service.getWalletById(1);

        expect(wallet, isA<SoftwareWallet>());
        expect((wallet as SoftwareWallet).seed, _testMnemonic);
      });

      test('returns DebugWallet for debug type', () async {
        when(() => repo.getWalletById(2)).thenAnswer(
          (_) async => _info(id: 2, name: 'Debug', address: _debugAddress, type: WalletType.debug),
        );

        final wallet = await service.getWalletById(2);

        expect(wallet, isA<DebugWallet>());
        expect((wallet as DebugWallet).address, _debugAddress);
      });

      test('throws when the repository returns null (no such id)', () async {
        when(() => repo.getWalletById(404)).thenAnswer((_) async => null);

        expect(() => service.getWalletById(404), throwsA(isA<TypeError>()));
      });
    });

    group('setCurrentWallet', () {
      test('delegates to SettingsRepository.saveCurrentWalletId', () async {
        await service.setCurrentWallet(5);

        verify(() => settings.saveCurrentWalletId(5)).called(1);
      });
    });

    group('getCurrentWallet', () {
      test('reads the current id and resolves it through getWalletById', () async {
        when(() => settings.currentWalletId).thenReturn(3);
        when(() => repo.getWalletById(3)).thenAnswer(
          (_) async => _info(id: 3, name: 'Saved', seed: _testMnemonic, type: WalletType.software),
        );

        final wallet = await service.getCurrentWallet();

        expect(wallet.id, 3);
        expect(wallet.name, 'Saved');
      });

      test('throws when no current id is set', () async {
        when(() => settings.currentWalletId).thenReturn(null);

        expect(() => service.getCurrentWallet(), throwsA(isA<TypeError>()));
      });
    });

    group('deleteCurrentWallet', () {
      test('deletes the wallet and clears the current-id setting', () async {
        when(() => settings.currentWalletId).thenReturn(8);

        await service.deleteCurrentWallet();

        verify(() => repo.deleteWallet(8)).called(1);
        verify(() => settings.removeCurrentWalletId()).called(1);
      });
    });

    group('hasWallet', () {
      test('returns true when a current id is set', () {
        when(() => settings.currentWalletId).thenReturn(1);

        expect(service.hasWallet(), isTrue);
      });

      test('returns false when no current id is set', () {
        when(() => settings.currentWalletId).thenReturn(null);

        expect(service.hasWallet(), isFalse);
      });
    });

    group('validateSeed', () {
      test('accepts a valid bip39 mnemonic', () {
        expect(service.validateSeed(_testMnemonic), isTrue);
      });

      test('rejects an obviously invalid mnemonic', () {
        expect(service.validateSeed('not a valid seed phrase at all'), isFalse);
      });

      test('rejects an empty string', () {
        expect(service.validateSeed(''), isFalse);
      });

      test('rejects a mnemonic with a wrong checksum word', () {
        // Replace the final checksum word with a different valid bip39 word.
        const broken =
            'test test test test test test test test test test test ability';
        expect(service.validateSeed(broken), isFalse);
      });
    });
  });
}
