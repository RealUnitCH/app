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
    // Default to a device that has a wallet set up so the existing pairing
    // tests reach the address-derivation path. The unseeded path is exercised
    // explicitly below.
    when(() => service.getDeviceStatus()).thenAnswer((_) async => 'initialized');
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
    Future<BitboxWallet> Function()? acquireWallet,
  }) => ConnectBitboxCubit(
    service,
    walletService,
    authService,
    confirmPairingTimeout: confirmPairingTimeout,
    createWalletTimeout: createWalletTimeout,
    pairingPinTimeout: pairingPinTimeout,
    acquireWallet: acquireWallet,
  );

  Future<void> waitForState<T>(
    ConnectBitboxCubit cubit, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (cubit.state is T) return;
    await cubit.stream.firstWhere((s) => s is T).timeout(timeout);
  }

  group('$ConnectBitboxCubit', () {
    test('reaches BitboxConnected via BitboxCapturingSignature when all succeed', () async {
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

      final emitted = <BitboxConnectionState>[];
      final sub = cubit.stream.listen(emitted.add);
      addTearDown(sub.cancel);

      await waitForState<BitboxCheckHash>(cubit);
      expect((cubit.state as BitboxCheckHash).channelHash, 'ABC123DEF456');

      final confirmFut = cubit.confirmPairing();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(cubit.state, isA<BitboxPairing>());

      initCompleter.complete(true);
      await confirmFut;

      expect(cubit.state, isA<BitboxConnected>());
      // The signature is captured as an awaited step before BitboxConnected.
      expect(emitted.whereType<BitboxCapturingSignature>(), isNotEmpty);
      verify(() => service.confirmPairing()).called(1);
      verify(() => walletService.createBitboxWallet(any())).called(1);
      verify(() => authService.ensureSignatureFor(any())).called(1);
    });

    test('a late scan tick neither stomps the state nor starts a second init '
        'while one is pending', () async {
      final initCompleter = Completer<bool>();
      var pollCount = 0;
      when(() => service.getAllUsbDevices()).thenAnswer((_) async => [device]);
      when(() => service.init(any())).thenAnswer((_) => initCompleter.future);
      when(() => service.getChannelHash()).thenAnswer((_) async {
        pollCount++;
        return pollCount < 2 ? '' : 'HASH-1';
      });

      final cubit = makeCubit();
      addTearDown(cubit.close);

      // First connect settles in BitboxCheckHash while init() is still pending.
      await waitForState<BitboxCheckHash>(cubit);
      verify(() => service.init(any())).called(1);

      // A late overlapping scan tick re-runs the full tick body.
      await cubit.checkForBitbox();

      // Must neither stomp the hash screen nor start a second init().
      verifyNever(() => service.init(any()));
      expect(cubit.state, isA<BitboxCheckHash>());
    });

    test('after a pairing-pin timeout the orphaned init gates fresh connects '
        'until it settles or the release cap elapses', () async {
      final initCompleter = Completer<bool>(); // never completes: zombie init
      var pollCount = 0;
      when(() => service.getAllUsbDevices()).thenAnswer((_) async => [device]);
      when(() => service.init(any())).thenAnswer((_) => initCompleter.future);
      when(() => service.getChannelHash()).thenAnswer((_) async {
        pollCount++;
        return pollCount < 2 ? '' : 'HASH-1';
      });

      final cubit = makeCubit(pairingPinTimeout: const Duration(milliseconds: 200));
      addTearDown(cubit.close);

      await waitForState<BitboxCheckHash>(cubit);
      verify(() => service.init(any())).called(1);

      await cubit.confirmPairing();
      expect(cubit.state, isA<BitboxNotConnected>());

      // The orphaned init() is still live: no second init(), no state stomp.
      await cubit.checkForBitbox();
      verifyNever(() => service.init(any()));
      expect(cubit.state, isA<BitboxNotConnected>());

      // Once the release cap elapses, the next tick pairs afresh (the tick
      // fires connectToBitbox unawaited, so give init() a beat).
      await Future<void>.delayed(const Duration(milliseconds: 250));
      await cubit.checkForBitbox();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      verify(() => service.init(any())).called(1);
    });

    test('a failed recheck after BitboxNotInitialized re-arms scanning that '
        'can actually reconnect', () async {
      var pollCount = 0;
      when(() => service.getAllUsbDevices()).thenAnswer((_) async => [device]);
      when(() => service.init(any())).thenAnswer((_) async => true);
      when(() => service.getChannelHash()).thenAnswer((_) async {
        pollCount++;
        return pollCount < 2 ? '' : 'HASH-1';
      });
      when(() => service.confirmPairing()).thenAnswer((_) async {});
      when(() => service.getDeviceStatus()).thenAnswer((_) async => 'uninitialized');

      final cubit = makeCubit();
      addTearDown(cubit.close);

      await waitForState<BitboxCheckHash>(cubit);
      verify(() => service.init(any())).called(1);

      await cubit.confirmPairing();
      expect(cubit.state, isA<BitboxNotInitialized>());

      // The user seeded the device; the wallet acquisition still fails once.
      when(() => service.getDeviceStatus()).thenAnswer((_) async => 'initialized');
      when(() => walletService.createBitboxWallet(any())).thenThrow(Exception('nope'));
      await cubit.recheckDeviceStatus();
      expect(cubit.state, isA<BitboxNotConnected>());

      // The consumed gate must allow a fresh pairing (tick fires connectToBitbox unawaited).
      await cubit.checkForBitbox();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      verify(() => service.init(any())).called(1);
    });

    test('emits BitboxSignatureFailed when the signature capture throws', () async {
      var pollCount = 0;
      when(() => service.getAllUsbDevices()).thenAnswer((_) async => [device]);
      when(() => service.init(any())).thenAnswer((_) async => true);
      when(() => service.getChannelHash()).thenAnswer((_) async {
        pollCount++;
        return pollCount < 3 ? '' : 'HASH-ok';
      });
      when(() => service.confirmPairing()).thenAnswer((_) async {});
      when(() => authService.ensureSignatureFor(any())).thenThrow(Exception('sign boom'));

      final cubit = makeCubit();
      addTearDown(cubit.close);

      final emitted = <BitboxConnectionState>[];
      final sub = cubit.stream.listen(emitted.add);
      addTearDown(sub.cancel);

      await waitForState<BitboxCheckHash>(cubit);
      await cubit.confirmPairing();

      expect(cubit.state, isA<BitboxSignatureFailed>());
      expect(emitted.whereType<BitboxCapturingSignature>(), isNotEmpty);
    });

    test('retrySignatureCapture recovers from BitboxSignatureFailed to BitboxConnected', () async {
      var pollCount = 0;
      var signCalls = 0;
      when(() => service.getAllUsbDevices()).thenAnswer((_) async => [device]);
      when(() => service.init(any())).thenAnswer((_) async => true);
      when(() => service.getChannelHash()).thenAnswer((_) async {
        pollCount++;
        return pollCount < 3 ? '' : 'HASH-ok';
      });
      when(() => service.confirmPairing()).thenAnswer((_) async {});
      when(() => authService.ensureSignatureFor(any())).thenAnswer((_) async {
        signCalls++;
        if (signCalls == 1) throw Exception('sign boom');
      });

      final cubit = makeCubit();
      addTearDown(cubit.close);

      await waitForState<BitboxCheckHash>(cubit);
      await cubit.confirmPairing();
      expect(cubit.state, isA<BitboxSignatureFailed>());

      await cubit.retrySignatureCapture();
      expect(cubit.state, isA<BitboxConnected>());
      verify(() => authService.ensureSignatureFor(any())).called(2);
    });

    test('retrySignatureCapture is a no-op when not in BitboxSignatureFailed', () async {
      final cubit = makeCubit();
      addTearDown(cubit.close);

      await cubit.retrySignatureCapture();
      expect(cubit.state, isA<BitboxNotConnected>());
    });

    test('continueWithoutSignature transitions BitboxSignatureFailed to BitboxConnected', () async {
      var pollCount = 0;
      when(() => service.getAllUsbDevices()).thenAnswer((_) async => [device]);
      when(() => service.init(any())).thenAnswer((_) async => true);
      when(() => service.getChannelHash()).thenAnswer((_) async {
        pollCount++;
        return pollCount < 3 ? '' : 'HASH-ok';
      });
      when(() => service.confirmPairing()).thenAnswer((_) async {});
      when(() => authService.ensureSignatureFor(any())).thenThrow(Exception('sign boom'));

      final cubit = makeCubit();
      addTearDown(cubit.close);

      await waitForState<BitboxCheckHash>(cubit);
      await cubit.confirmPairing();
      expect(cubit.state, isA<BitboxSignatureFailed>());

      cubit.continueWithoutSignature();
      expect(cubit.state, isA<BitboxConnected>());
    });

    test('continueWithoutSignature is a no-op when not in BitboxSignatureFailed', () async {
      final cubit = makeCubit();
      addTearDown(cubit.close);

      cubit.continueWithoutSignature();
      expect(cubit.state, isA<BitboxNotConnected>());
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

    test('falls back to NotConnected when init resolves with an async error', () async {
      // The above test makes `init` throw synchronously, which short-circuits
      // before the `.then`/`.catchError` chain attached on `_pendingInit` is
      // exercised. To cover the catchError branch (the host-side init future
      // resolving with an error after the call returned) we hand back a
      // future that completes with an error asynchronously.
      when(() => service.getAllUsbDevices()).thenAnswer((_) async => [device]);
      when(
        () => service.init(any()),
      ).thenAnswer((_) => Future<bool>.error(Exception('async init boom')));
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

    // Recovery flow injection: when an `acquireWallet` override is supplied
    // (the address-recovery page passes `healCurrentBitboxAddress`), the cubit
    // must call IT instead of the default `createBitboxWallet`, so re-pairing
    // backfills the existing row rather than creating a second wallet.
    test('confirmPairing uses the injected acquireWallet instead of createBitboxWallet', () async {
      var pollCount = 0;
      when(() => service.getAllUsbDevices()).thenAnswer((_) async => [device]);
      when(() => service.init(any())).thenAnswer((_) async => true);
      when(() => service.getChannelHash()).thenAnswer((_) async {
        pollCount++;
        return pollCount < 3 ? '' : 'HASH-ok';
      });
      when(() => service.confirmPairing()).thenAnswer((_) async {});

      var acquireCalls = 0;
      final cubit = makeCubit(
        acquireWallet: () async {
          acquireCalls++;
          return wallet;
        },
      );
      addTearDown(cubit.close);

      await waitForState<BitboxCheckHash>(cubit);
      await cubit.confirmPairing();

      expect(cubit.state, isA<BitboxConnected>());
      expect(acquireCalls, 1, reason: 'the injected acquireWallet must be the wallet source');
      // The default path must NOT run when an override is supplied.
      verifyNever(() => walletService.createBitboxWallet(any()));
      verify(() => authService.ensureSignatureFor(any())).called(1);
    });

    test('confirmPairing falls back to createBitboxWallet when no override is given', () async {
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
      verify(() => walletService.createBitboxWallet('Luke-Skywallet')).called(1);
    });

    // A brand-new device with no wallet (firmware status `uninitialized`) cannot
    // derive an address. It must surface BitboxNotInitialized — not the generic
    // failure — and must NOT try to create a wallet or arm the re-scan timer that
    // would re-pair the device in an endless loop.
    test('emits BitboxNotInitialized when the device has no wallet set up', () async {
      var pollCount = 0;
      when(() => service.getAllUsbDevices()).thenAnswer((_) async => [device]);
      when(() => service.init(any())).thenAnswer((_) async => true);
      when(() => service.getChannelHash()).thenAnswer((_) async {
        pollCount++;
        return pollCount < 3 ? '' : 'HASH-ok';
      });
      when(() => service.confirmPairing()).thenAnswer((_) async {});
      when(() => service.getDeviceStatus()).thenAnswer((_) async => 'uninitialized');

      final cubit = makeCubit();
      addTearDown(cubit.close);

      await waitForState<BitboxCheckHash>(cubit);
      await cubit.confirmPairing();

      expect(cubit.state, isA<BitboxNotInitialized>());
      verifyNever(() => walletService.createBitboxWallet(any()));

      // The state must be stable: no re-scan timer is armed, so the cubit does
      // not bounce back through the connection flow on its own.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cubit.state, isA<BitboxNotInitialized>());
    });

    test('recheckDeviceStatus continues to BitboxConnected once a wallet is set up', () async {
      var pollCount = 0;
      var statusCalls = 0;
      when(() => service.getAllUsbDevices()).thenAnswer((_) async => [device]);
      when(() => service.init(any())).thenAnswer((_) async => true);
      when(() => service.getChannelHash()).thenAnswer((_) async {
        pollCount++;
        return pollCount < 3 ? '' : 'HASH-ok';
      });
      when(() => service.confirmPairing()).thenAnswer((_) async {});
      when(() => service.getDeviceStatus()).thenAnswer((_) async {
        statusCalls++;
        return statusCalls == 1 ? 'uninitialized' : 'initialized';
      });

      final cubit = makeCubit();
      addTearDown(cubit.close);

      await waitForState<BitboxCheckHash>(cubit);
      await cubit.confirmPairing();
      expect(cubit.state, isA<BitboxNotInitialized>());

      await cubit.recheckDeviceStatus();
      expect(cubit.state, isA<BitboxConnected>());
      verify(() => walletService.createBitboxWallet(any())).called(1);
    });

    test(
      'recheckDeviceStatus stays in BitboxNotInitialized while the device is still unseeded',
      () async {
        var pollCount = 0;
        when(() => service.getAllUsbDevices()).thenAnswer((_) async => [device]);
        when(() => service.init(any())).thenAnswer((_) async => true);
        when(() => service.getChannelHash()).thenAnswer((_) async {
          pollCount++;
          return pollCount < 3 ? '' : 'HASH-ok';
        });
        when(() => service.confirmPairing()).thenAnswer((_) async {});
        when(() => service.getDeviceStatus()).thenAnswer((_) async => 'uninitialized');

        final cubit = makeCubit();
        addTearDown(cubit.close);

        await waitForState<BitboxCheckHash>(cubit);
        await cubit.confirmPairing();
        expect(cubit.state, isA<BitboxNotInitialized>());

        await cubit.recheckDeviceStatus();
        expect(cubit.state, isA<BitboxNotInitialized>());
        verifyNever(() => walletService.createBitboxWallet(any()));
      },
    );

    test('recheckDeviceStatus is a no-op when not in BitboxNotInitialized', () async {
      final cubit = makeCubit();
      addTearDown(cubit.close);

      await cubit.recheckDeviceStatus();
      expect(cubit.state, isA<BitboxNotConnected>());
    });

    test('recheckDeviceStatus falls back to NotConnected when acquireWallet throws', () async {
      var pollCount = 0;
      when(() => service.getAllUsbDevices()).thenAnswer((_) async => [device]);
      when(() => service.init(any())).thenAnswer((_) async => true);
      when(() => service.getChannelHash()).thenAnswer((_) async {
        pollCount++;
        return pollCount < 3 ? '' : 'HASH-ok';
      });
      when(() => service.confirmPairing()).thenAnswer((_) async {});
      // First call: device unseeded → BitboxNotInitialized.
      // Second call (recheckDeviceStatus): device now seeded, but wallet
      // acquisition fails → catch block must emit BitboxNotConnected.
      var statusCalls = 0;
      when(() => service.getDeviceStatus()).thenAnswer((_) async {
        statusCalls++;
        return statusCalls == 1 ? 'uninitialized' : 'initialized';
      });
      when(() => walletService.createBitboxWallet(any())).thenThrow(Exception('wallet boom'));

      final cubit = makeCubit();
      addTearDown(cubit.close);

      await waitForState<BitboxCheckHash>(cubit);
      await cubit.confirmPairing();
      expect(cubit.state, isA<BitboxNotInitialized>());

      await cubit.recheckDeviceStatus();
      expect(cubit.state, isA<BitboxNotConnected>());
    });

    // Fail-open guarantee: a failing status read must NOT block a device that
    // would otherwise pair. If getDeviceStatus throws, the flow falls through to
    // the normal acquire path and still reaches BitboxConnected — the new gate
    // can only ever ADD the unseeded path, never break the working one.
    test('continues to BitboxConnected when the status read throws', () async {
      var pollCount = 0;
      when(() => service.getAllUsbDevices()).thenAnswer((_) async => [device]);
      when(() => service.init(any())).thenAnswer((_) async => true);
      when(() => service.getChannelHash()).thenAnswer((_) async {
        pollCount++;
        return pollCount < 3 ? '' : 'HASH-ok';
      });
      when(() => service.confirmPairing()).thenAnswer((_) async {});
      when(() => service.getDeviceStatus()).thenThrow(Exception('status boom'));

      final cubit = makeCubit();
      addTearDown(cubit.close);

      await waitForState<BitboxCheckHash>(cubit);
      await cubit.confirmPairing();

      expect(cubit.state, isA<BitboxConnected>());
      verify(() => walletService.createBitboxWallet(any())).called(1);
    });
  });
}
