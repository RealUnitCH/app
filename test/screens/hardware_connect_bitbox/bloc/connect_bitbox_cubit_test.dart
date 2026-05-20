import 'dart:async';

import 'package:bitbox_flutter/bitbox_flutter.dart' as sdk;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_auth_service.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/packages/wallet/wallet_account.dart';
import 'package:realunit_wallet/screens/hardware_connect_bitbox/bloc/connect_bitbox_cubit.dart';

class _MockBitboxService extends Mock implements BitboxService {}

class _MockWalletService extends Mock implements WalletService {}

class _MockBitboxWallet extends Mock implements BitboxWallet {}

class _MockAuthService extends Mock implements DFXAuthService {}

class _FakeBitboxDevice extends Fake implements sdk.BitboxDevice {}

class _FakeBitboxWalletAccount extends Fake implements BitboxWalletAccount {}

void main() {
  late _MockBitboxService service;
  late _MockWalletService walletService;
  late _MockAuthService authService;
  late _FakeBitboxDevice device;
  late _MockBitboxWallet wallet;

  setUpAll(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    registerFallbackValue(_FakeBitboxDevice());
    registerFallbackValue(_FakeBitboxWalletAccount());
  });

  tearDownAll(() {
    debugDefaultTargetPlatformOverride = null;
  });

  setUp(() {
    service = _MockBitboxService();
    walletService = _MockWalletService();
    authService = _MockAuthService();
    device = _FakeBitboxDevice();
    wallet = _MockBitboxWallet();

    when(() => service.startScan()).thenAnswer((_) async => true);
    when(() => service.getAllUsbDevices()).thenAnswer((_) async => []);
    when(() => service.startConnectionStatusObserver()).thenReturn(null);
    when(() => walletService.createBitboxWallet(any())).thenAnswer((_) async => wallet);
    when(() => wallet.currentAccount).thenReturn(_FakeBitboxWalletAccount());
    when(() => authService.ensureSignatureFor(any())).thenAnswer((_) async {});
  });

  // Tests pass in short timeouts so the bounce-back path can be exercised in
  // real time. Production defaults are 75s/30s/120s.
  ConnectBitboxCubit makeCubit({
    Duration confirmPairingTimeout = const Duration(milliseconds: 500),
    Duration createWalletTimeout = const Duration(milliseconds: 500),
    Duration pairingPinTimeout = const Duration(milliseconds: 500),
  }) => ConnectBitboxCubit(
    service,
    walletService,
    authService,
    confirmPairingTimeout: confirmPairingTimeout,
    createWalletTimeout: createWalletTimeout,
    pairingPinTimeout: pairingPinTimeout,
  );

  Future<void> waitForState<T>(
    ConnectBitboxCubit cubit, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (cubit.state is T) return;
    await cubit.stream.firstWhere((s) => s is T).timeout(timeout);
  }

  group('$ConnectBitboxCubit', () {
    test('reaches BitboxConnected when device, hash, init, verify all succeed', () async {
      final initCompleter = Completer<bool>();
      var pollCount = 0;

      when(() => service.getAllUsbDevices()).thenAnswer((_) async => [device]);
      when(() => service.init(any())).thenAnswer((_) => initCompleter.future);
      when(() => service.getChannelHash()).thenAnswer((_) async {
        pollCount++;
        return pollCount < 3 ? '' : 'ABC123DEF456';
      });
      when(() => service.confirmPairing()).thenAnswer((_) async {});

      final cubit = makeCubit();
      addTearDown(cubit.close);

      await waitForState<BitboxCheckHash>(cubit);
      expect((cubit.state as BitboxCheckHash).channelHash, 'ABC123DEF456');

      final confirmFut = cubit.confirmPairing();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(cubit.state, isA<BitboxPairing>());

      initCompleter.complete(true);
      await confirmFut;

      expect(cubit.state, isA<BitboxConnected>());
      verify(() => service.confirmPairing()).called(1);
      verify(() => walletService.createBitboxWallet(any())).called(1);
    });

    test('finishSetup transitions BitboxConnected to BitboxFinishSetup', () async {
      var pollCount = 0;
      when(() => service.getAllUsbDevices()).thenAnswer((_) async => [device]);
      when(() => service.init(any())).thenAnswer((_) async => true);
      when(() => service.getChannelHash()).thenAnswer((_) async {
        pollCount++;
        return pollCount < 3 ? '' : 'HASH-ok';
      });
      when(() => service.confirmPairing()).thenAnswer((_) async {});

      final cubit = makeCubit();
      addTearDown(cubit.close);

      await waitForState<BitboxCheckHash>(cubit);
      await cubit.confirmPairing();

      expect(cubit.state, isA<BitboxConnected>());
      cubit.finishSetup();
      expect(cubit.state, isA<BitboxFinishSetup>());
    });

    test('ignores a stale channel hash cached from a previous session', () async {
      final responses = <String>[
        'STALE-PRIOR', // priorHash snapshot
        'STALE-PRIOR', // first poll iteration
        'STALE-PRIOR', // second iteration
        'FRESH-NEW',
      ];
      when(() => service.getAllUsbDevices()).thenAnswer((_) async => [device]);
      when(() => service.init(any())).thenAnswer((_) async => true);
      when(() => service.getChannelHash()).thenAnswer(
        (_) async => responses.isEmpty ? 'FRESH-NEW' : responses.removeAt(0),
      );
      when(() => service.confirmPairing()).thenAnswer((_) async {});

      final cubit = makeCubit();
      addTearDown(cubit.close);

      await waitForState<BitboxCheckHash>(cubit);
      expect((cubit.state as BitboxCheckHash).channelHash, 'FRESH-NEW');
    });

    test('falls back to NotConnected when init returns false', () async {
      when(() => service.getAllUsbDevices()).thenAnswer((_) async => [device]);
      when(() => service.init(any())).thenAnswer((_) async => false);
      when(() => service.getChannelHash()).thenAnswer((_) async => '');

      final cubit = makeCubit();
      addTearDown(cubit.close);

      await cubit.stream
          .firstWhere((s) => s is BitboxNotConnected)
          .timeout(const Duration(seconds: 3));
      expect(cubit.state, isA<BitboxNotConnected>());
    });

    test('falls back to NotConnected when init throws', () async {
      when(() => service.getAllUsbDevices()).thenAnswer((_) async => [device]);
      when(() => service.init(any())).thenThrow(Exception('boom'));
      when(() => service.getChannelHash()).thenAnswer((_) async => '');

      final cubit = makeCubit();
      addTearDown(cubit.close);

      await cubit.stream
          .firstWhere((s) => s is BitboxNotConnected)
          .timeout(const Duration(seconds: 3));
      expect(cubit.state, isA<BitboxNotConnected>());
    });

    test('bounces to NotConnected when confirmPairing hangs past the timeout', () async {
      var pollCount = 0;
      when(() => service.getAllUsbDevices()).thenAnswer((_) async => [device]);
      when(() => service.init(any())).thenAnswer((_) async => true);
      when(() => service.getChannelHash()).thenAnswer((_) async {
        pollCount++;
        return pollCount < 3 ? '' : 'HASH-ok';
      });
      when(() => service.confirmPairing()).thenAnswer((_) => Completer<void>().future);

      final cubit = makeCubit(confirmPairingTimeout: const Duration(milliseconds: 200));
      addTearDown(cubit.close);

      await waitForState<BitboxCheckHash>(cubit);
      unawaited(cubit.confirmPairing());
      await waitForState<BitboxPairing>(cubit);
      await cubit.stream
          .firstWhere((s) => s is BitboxNotConnected)
          .timeout(const Duration(seconds: 2));
      expect(cubit.state, isA<BitboxNotConnected>());
    });

    test('bounces to NotConnected when init never resolves past pairingPinTimeout', () async {
      // `_pendingInit` is awaited inside `confirmPairing()`. If the user
      // never presses the device-side pairing button, init stays pending —
      // the new `pairingPinTimeout` outer cap turns that into a typed
      // failure path back to BitboxNotConnected.
      var pollCount = 0;
      when(() => service.getAllUsbDevices()).thenAnswer((_) async => [device]);
      when(() => service.init(any())).thenAnswer((_) => Completer<bool>().future);
      when(() => service.getChannelHash()).thenAnswer((_) async {
        pollCount++;
        return pollCount < 3 ? '' : 'HASH-ok';
      });

      final cubit = makeCubit(pairingPinTimeout: const Duration(milliseconds: 200));
      addTearDown(cubit.close);

      await waitForState<BitboxCheckHash>(cubit);
      unawaited(cubit.confirmPairing());
      await waitForState<BitboxPairing>(cubit);
      await cubit.stream
          .firstWhere((s) => s is BitboxNotConnected)
          .timeout(const Duration(seconds: 2));
      expect(cubit.state, isA<BitboxNotConnected>());
      verifyNever(() => service.confirmPairing());
    });

    // BitBox quirk P1 (pairing-channel-hash-before-confirm): the channel hash
    // must reach the UI before the host calls confirmPairing on the device,
    // otherwise the user has no way to verify the hash matches the device
    // display. The cubit enforces this by emitting BitboxCheckHash before
    // user-driven confirmPairing() ever invokes the service.
    test('emits BitboxCheckHash before service.confirmPairing is called (P1)', () async {
      var pollCount = 0;
      when(() => service.getAllUsbDevices()).thenAnswer((_) async => [device]);
      when(() => service.init(any())).thenAnswer((_) async => true);
      when(() => service.getChannelHash()).thenAnswer((_) async {
        pollCount++;
        return pollCount < 3 ? '' : 'HASH-VISIBLE-TO-USER';
      });
      when(() => service.confirmPairing()).thenAnswer((_) async {});

      final cubit = makeCubit();
      addTearDown(cubit.close);

      await waitForState<BitboxCheckHash>(cubit);
      expect(
        (cubit.state as BitboxCheckHash).channelHash,
        'HASH-VISIBLE-TO-USER',
      );
      verifyNever(() => service.confirmPairing());

      await cubit.confirmPairing();
      verify(() => service.confirmPairing()).called(1);
    });

    test('bounces to NotConnected when createBitboxWallet hangs past the timeout', () async {
      var pollCount = 0;
      when(() => service.getAllUsbDevices()).thenAnswer((_) async => [device]);
      when(() => service.init(any())).thenAnswer((_) async => true);
      when(() => service.getChannelHash()).thenAnswer((_) async {
        pollCount++;
        return pollCount < 3 ? '' : 'HASH-ok';
      });
      when(() => service.confirmPairing()).thenAnswer((_) async {});
      when(
        () => walletService.createBitboxWallet(any()),
      ).thenAnswer((_) => Completer<BitboxWallet>().future);

      final cubit = makeCubit(createWalletTimeout: const Duration(milliseconds: 200));
      addTearDown(cubit.close);

      await waitForState<BitboxCheckHash>(cubit);
      unawaited(cubit.confirmPairing());
      await waitForState<BitboxPairing>(cubit);
      await cubit.stream
          .firstWhere((s) => s is BitboxNotConnected)
          .timeout(const Duration(seconds: 2));
      expect(cubit.state, isA<BitboxNotConnected>());
    });
  });
}
