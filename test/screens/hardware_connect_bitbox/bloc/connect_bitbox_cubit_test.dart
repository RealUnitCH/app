import 'dart:async';

import 'package:bitbox_flutter/bitbox_flutter.dart' as sdk;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox_connection_status.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_auth_service.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/packages/wallet/wallet_account.dart';
import 'package:realunit_wallet/screens/hardware_connect_bitbox/bloc/connect_bitbox_cubit.dart';

class _MockBitboxService extends Mock implements BitboxService {}

class _MockWalletService extends Mock implements WalletService {}

class _MockBitboxWallet extends Mock implements BitboxWallet {}

class _MockAuthService extends Mock implements DFXAuthService {}

class _FakeBitboxDevice extends Fake implements sdk.BitboxDevice {
  @override
  String get identifier => 'fake-device';
}

class _FakeBitboxWalletAccount extends Fake implements BitboxWalletAccount {}

void main() {
  late _MockBitboxService service;
  late _MockWalletService walletService;
  late _MockAuthService authService;
  late _FakeBitboxDevice device;
  late _MockBitboxWallet wallet;
  late StreamController<BitboxConnectionStatus> statusController;

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
    statusController = StreamController<BitboxConnectionStatus>.broadcast();

    when(() => service.startScan()).thenAnswer((_) async => true);
    when(() => service.getAllUsbDevices()).thenAnswer((_) async => []);
    when(() => service.startConnectionStatusObserver()).thenReturn(null);
    when(() => service.status).thenAnswer((_) => statusController.stream);
    when(() => walletService.createBitboxWallet(any())).thenAnswer((_) async => wallet);
    when(() => wallet.currentAccount).thenReturn(_FakeBitboxWalletAccount());
    when(() => authService.ensureSignatureFor(any())).thenAnswer((_) async {});
  });

  tearDown(() async {
    await statusController.close();
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
    test('reaches BitboxConnected via BitboxCapturingSignature when all succeed', () async {
      final initCompleter = Completer<BitboxConnectionStatus>();
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

      initCompleter.complete(Paired(device));
      await confirmFut;

      expect(cubit.state, isA<BitboxConnected>());
      // The signature is captured as an awaited step before BitboxConnected.
      expect(emitted.whereType<BitboxCapturingSignature>(), isNotEmpty);
      verify(() => service.confirmPairing()).called(1);
      verify(() => walletService.createBitboxWallet(any())).called(1);
      verify(() => authService.ensureSignatureFor(any())).called(1);
    });

    test('emits BitboxSignatureFailed when the signature capture throws', () async {
      var pollCount = 0;
      when(() => service.getAllUsbDevices()).thenAnswer((_) async => [device]);
      when(() => service.init(any())).thenAnswer((_) async => Paired(device));
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
      when(() => service.init(any())).thenAnswer((_) async => Paired(device));
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
      when(() => service.init(any())).thenAnswer((_) async => Paired(device));
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
      when(() => service.init(any())).thenAnswer((_) async => Paired(device));
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
      when(() => service.init(any())).thenAnswer((_) async => Paired(device));
      when(() => service.getChannelHash()).thenAnswer(
        (_) async => responses.isEmpty ? 'FRESH-NEW' : responses.removeAt(0),
      );
      when(() => service.confirmPairing()).thenAnswer((_) async {});

      final cubit = makeCubit();
      addTearDown(cubit.close);

      await waitForState<BitboxCheckHash>(cubit);
      expect((cubit.state as BitboxCheckHash).channelHash, 'FRESH-NEW');
    });

    test('falls back to NotConnected when init resolves to Disconnected', () async {
      // Post-Initiative-I: init() now returns a BitboxConnectionStatus. A
      // resolution that is NOT Paired/InUse means pairing did not land, so
      // the cubit must bounce to BitboxNotConnected.
      when(() => service.getAllUsbDevices()).thenAnswer((_) async => [device]);
      when(() => service.init(any())).thenAnswer((_) async => const Disconnected());
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
      ).thenAnswer(
        (_) => Future<BitboxConnectionStatus>.error(
          Exception('async init boom'),
        ),
      );
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
      when(() => service.init(any())).thenAnswer((_) async => Paired(device));
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
      when(() => service.init(any())).thenAnswer((_) => Completer<BitboxConnectionStatus>().future);
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
      when(() => service.init(any())).thenAnswer((_) async => Paired(device));
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
      when(() => service.init(any())).thenAnswer((_) async => Paired(device));
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

    // -----------------------------------------------------------------------
    // Initiative I — BitboxService.status stream subscription
    //
    // Post-ADR-0001 the cubit subscribes to the service's lifecycle stream
    // so a service-side Lost (e.g. sign-queue timeout, observer device
    // vanish) bounces the cubit back to BitboxNotConnected without forcing
    // each individual try/catch to also poll currentStatus.
    // -----------------------------------------------------------------------

    test('subscribes to BitboxService.status on construction', () {
      // The cubit's construction must register exactly one stream
      // subscription. Without it the Lost-routing below would silently
      // no-op.
      final cubit = makeCubit();
      addTearDown(cubit.close);

      verify(() => service.status).called(1);
      expect(
        statusController.hasListener,
        isTrue,
        reason: 'cubit must hold a live subscription after construction',
      );
    });

    test('service-emitted Lost bounces an in-progress pairing back to NotConnected', () async {
      // Mid-flow scenario: cubit has reached BitboxCheckHash, sign-queue
      // timeout fires on the service side and emits Lost. The cubit must
      // bounce to BitboxNotConnected and re-arm the scan timer without
      // requiring the user to manually unplug.
      var pollCount = 0;
      when(() => service.getAllUsbDevices()).thenAnswer((_) async => [device]);
      when(() => service.init(any())).thenAnswer((_) async => Paired(device));
      when(() => service.getChannelHash()).thenAnswer((_) async {
        pollCount++;
        return pollCount < 3 ? '' : 'HASH-ok';
      });

      final cubit = makeCubit();
      addTearDown(cubit.close);
      await waitForState<BitboxCheckHash>(cubit);

      // Service flips to Lost mid-flow. Cubit must observe the transition
      // and route back to BitboxNotConnected.
      statusController.add(const Lost(LostReason.signQueueTimeout));
      await cubit.stream
          .firstWhere((s) => s is BitboxNotConnected)
          .timeout(const Duration(seconds: 2));
      expect(cubit.state, isA<BitboxNotConnected>());
    });

    test('non-Lost transitions on the status stream do NOT spuriously bounce', () async {
      // Defensive: emitting Paired or Connecting from the service must not
      // flip the cubit's UX state. Only Lost is load-bearing.
      final cubit = makeCubit();
      addTearDown(cubit.close);
      final emitted = <BitboxConnectionState>[];
      final sub = cubit.stream.listen(emitted.add);
      addTearDown(sub.cancel);

      statusController.add(const Disconnected());
      statusController.add(Connecting(device));
      statusController.add(Paired(device));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(
        emitted.whereType<BitboxNotConnected>().toList(),
        isEmpty,
        reason: 'non-Lost transitions must not perturb the cubit state',
      );
    });

    test('close() cancels the status subscription (no leak after close)', () async {
      final cubit = makeCubit();
      expect(statusController.hasListener, isTrue);
      await cubit.close();
      expect(
        statusController.hasListener,
        isFalse,
        reason: 'close() must cancel the cubit\'s status subscription',
      );
    });

    test('Lost emitted after close() does NOT throw or emit', () async {
      // Defensive: a Lost arriving after `close()` (e.g. service emitting
      // during cubit teardown) must be ignored without throwing.
      final cubit = makeCubit();
      final emitted = <BitboxConnectionState>[];
      final sub = cubit.stream.listen(emitted.add);
      await cubit.close();
      await sub.cancel();

      statusController.add(const Lost(LostReason.deviceUnreachable));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      // No assertion beyond "no throw" — the cancel above must have
      // detached, so no further state-emission is even possible.
      expect(emitted.whereType<BitboxNotConnected>(), isEmpty);
    });
  });
}
