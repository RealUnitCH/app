// Cross-layer integration tests for the BitBox pairing flow.
//
// These tests stitch the ConnectBitboxCubit together with a *real*
// BitboxService driven by the official bitbox_flutter simulator
// (SimulatedBitboxPlatform installed at the BitboxUsbPlatform.instance
// seam). The four touchpoints the cubit makes against the device boundary —
// startScan / pair (init) / getChannelHash / confirmPairing — go through
// the production code, not a mock. Downstream collaborators that don't
// belong to the BitBox boundary (WalletService.createBitboxWallet,
// DFXAuthService.ensureSignatureFor) are stubbed: they have their own
// dedicated suites, and a regression in those layers must not surface as
// a noisy failure here.
//
// Style anchor: test/integration/kyc_sign_flow_test.dart and
// test/packages/hardware_wallet/bitbox_service_test.dart (the simulator
// install / tearDown pattern).

import 'package:bitbox_flutter/bitbox_flutter.dart' as sdk;
import 'package:bitbox_flutter/testing.dart';
import 'package:bitbox_flutter/usb/bitbox_usb_platform_interface.dart';
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

class _MockWalletService extends Mock implements WalletService {}

class _MockAuthService extends Mock implements DFXAuthService {}

class _MockBitboxWallet extends Mock implements BitboxWallet {}

class _FakeBitboxWalletAccount extends Fake implements BitboxWalletAccount {}

void main() {
  // Polling cadence inside the cubit is hard-wired to 500 ms / 100 ms in
  // production. Keep the observer tick fast so the disconnect cases settle
  // well under the per-test timeout without leaning on long real-time waits.
  const fastObserverInterval = Duration(milliseconds: 25);

  late BitboxUsbPlatform previousPlatform;
  late SimulatedBitboxPlatform platform;
  late BitboxService service;
  late _MockWalletService walletService;
  late _MockAuthService authService;
  late _MockBitboxWallet wallet;

  setUpAll(() {
    // _startScanning gates the startScan call on `DeviceInfo.instance.isIOS`;
    // the test default platform is android and would skip the call entirely.
    // Force iOS so the startScan touchpoint is actually exercised.
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    registerFallbackValue(_FakeBitboxWalletAccount());
  });

  tearDownAll(() {
    debugDefaultTargetPlatformOverride = null;
  });

  setUp(() {
    previousPlatform = BitboxUsbPlatform.instance;
    platform = installSimulatedBitboxPlatform();
    service = BitboxService(connectionStatusInterval: fastObserverInterval);
    walletService = _MockWalletService();
    authService = _MockAuthService();
    wallet = _MockBitboxWallet();

    when(() => walletService.createBitboxWallet(any())).thenAnswer((_) async => wallet);
    when(() => wallet.currentAccount).thenReturn(_FakeBitboxWalletAccount());
    when(() => authService.ensureSignatureFor(any())).thenAnswer((_) async {});
  });

  tearDown(() {
    BitboxUsbPlatform.instance = previousPlatform;
  });

  // Short host-side timeouts so the bounce-back / failure paths surface
  // promptly. Production defaults are 75 s / 30 s / 120 s.
  ConnectBitboxCubit makeCubit() => ConnectBitboxCubit(
    service,
    walletService,
    authService,
    confirmPairingTimeout: const Duration(milliseconds: 500),
    createWalletTimeout: const Duration(milliseconds: 500),
    pairingPinTimeout: const Duration(milliseconds: 500),
  );

  Future<void> waitForState<T>(
    ConnectBitboxCubit cubit, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    if (cubit.state is T) return;
    await cubit.stream.firstWhere((s) => s is T).timeout(timeout);
  }

  // The simulator's default channel hash is a constant string — the cubit's
  // polling loop snapshots an initial "prior hash" and then waits for a
  // *different* value to surface. Rotate the hash to something fresh so the
  // first observed hash counts as a new pairing session.
  void primeFreshChannelHash() {
    platform.when(
      SimulatedBitboxMethod.getChannelHash,
      (_) async => 'fresh-channel-hash',
    );
  }

  group('$ConnectBitboxCubit × BitboxService × SimulatedBitboxPlatform', () {
    test(
      'happy: initial pair → channel-hash shown → confirmPairing → BitboxConnected',
      () async {
        // Drives the four BitBox touchpoints end-to-end against the
        // simulator: getAllUsbDevices (scan loop) → init (connect+initBitBox)
        // → getChannelHash → confirmPairing (channelHashVerify). Failure on
        // any of these silently flips the state machine back to
        // BitboxNotConnected, so the assertions pin both the terminal state
        // AND the touchpoint counts.
        primeFreshChannelHash();

        final cubit = makeCubit();
        addTearDown(cubit.close);

        await waitForState<BitboxCheckHash>(cubit);
        expect((cubit.state as BitboxCheckHash).channelHash, 'fresh-channel-hash');

        await cubit.confirmPairing();

        expect(cubit.state, isA<BitboxConnected>());
        expect(
          platform.count(SimulatedBitboxMethod.initBitBox),
          greaterThanOrEqualTo(1),
          reason: 'init must have driven the simulator init touchpoint',
        );
        expect(
          platform.count(SimulatedBitboxMethod.getChannelHash),
          greaterThanOrEqualTo(1),
          reason: 'channel-hash must be polled at least once before the user verifies',
        );
        expect(
          platform.count(SimulatedBitboxMethod.channelHashVerify),
          1,
          reason: 'confirmPairing routes exactly one verify call to the device',
        );
        verify(() => walletService.createBitboxWallet(any())).called(1);
        verify(() => authService.ensureSignatureFor(any())).called(1);
      },
    );

    test(
      'pair-rejected: simulator rejects channelHashVerify → cubit bounces to BitboxNotConnected',
      () async {
        // confirmPairing surfaces the simulator's reject as
        // `Exception("Failed to verify")` inside BitboxService.confirmPairing.
        // The cubit's confirmPairing catches that, drops _pendingInit, and
        // re-arms the scan loop — so a typed BitboxNotConnected state is the
        // user-visible result, not a bare thrown future.
        primeFreshChannelHash();
        platform.when(
          SimulatedBitboxMethod.channelHashVerify,
          (_) async => false,
        );

        final cubit = makeCubit();
        addTearDown(cubit.close);

        await waitForState<BitboxCheckHash>(cubit);

        // Subscribe AFTER BitboxCheckHash so the post-rejection
        // NotConnected transition is observable. The scan loop normally
        // re-emits BitboxNotConnected → BitboxFound on every tick, so we
        // anchor on confirmPairing kicking the cubit back to NotConnected
        // before any subsequent BitboxFound restart.
        final transitions = <BitboxConnectionState>[];
        final sub = cubit.stream.listen(transitions.add);
        addTearDown(sub.cancel);

        await cubit.confirmPairing();
        // Flush a microtask hop so the catch's emit propagates through the
        // bloc stream to the listener — `confirmPairing` resolves on the
        // same synchronous tick the emit fires, so the listener has not yet
        // observed BitboxNotConnected at that exact moment.
        await Future<void>.delayed(Duration.zero);

        expect(
          transitions.whereType<BitboxPairing>(),
          isNotEmpty,
          reason: 'confirmPairing must emit BitboxPairing before bouncing',
        );
        expect(
          transitions.whereType<BitboxNotConnected>(),
          isNotEmpty,
          reason: 'a rejected channel-hash verify must surface as BitboxNotConnected',
        );
        // The wallet must NOT be created or signed for when pairing fails:
        // createBitboxWallet is downstream of confirmPairing in the cubit
        // body, and a stray call here would mean we persisted a half-paired
        // hardware wallet row.
        verifyNever(() => walletService.createBitboxWallet(any()));
        verifyNever(() => authService.ensureSignatureFor(any()));
      },
    );

    test(
      'observer-disconnect: device vanishes after pair → observer clears credentials',
      () async {
        // The cubit arms `service.startConnectionStatusObserver()` as the
        // last act of a successful confirmPairing. After that, the periodic
        // observer in BitboxService polls the device list; on the first
        // empty result it must call clearBitbox() on every cached set of
        // credentials. This pins the bridge between cubit success and the
        // post-pairing recovery loop.
        primeFreshChannelHash();

        final cubit = makeCubit();
        addTearDown(cubit.close);

        await waitForState<BitboxCheckHash>(cubit);
        await cubit.confirmPairing();
        expect(cubit.state, isA<BitboxConnected>());

        // Take a handle on the credentials the observer is supposed to
        // clear. SimulatedBitboxPlatform's default ETH address is the same
        // string the cubit's downstream createBitboxWallet would normally
        // derive — feed that into getCredentials so observer-driven
        // clearBitbox() and our assertion see the same map entry.
        final credentials = service.getCredentials(
          '0x1111111111111111111111111111111111111111',
        );
        expect(
          credentials.isConnected,
          isTrue,
          reason: 'after pairing, credentials must come back connected',
        );

        // Simulate the user yanking the cable: every subsequent device
        // probe returns an empty list. The observer is already running
        // (started inside confirmPairing's success branch) so we don't
        // need to call startConnectionStatusObserver() ourselves.
        platform.when(
          SimulatedBitboxMethod.getDevices,
          (_) async => const <sdk.BitboxDevice>[],
        );

        // Two intervals' worth of virtual time → the observer is guaranteed
        // to have ticked at least once and entered the device-loss branch.
        await Future<void>.delayed(fastObserverInterval * 4);

        expect(
          credentials.isConnected,
          isFalse,
          reason: 'observer must clear the credentials on device-loss',
        );
      },
    );

    test(
      're-pair-after-disconnect: first pair OK, device vanishes, reappears → re-pair succeeds',
      () async {
        // Defends the P461 #1 contract: after an observer-driven device-loss
        // the same credentials reference must heal once init() is called
        // again. Without that, a wallet built before the disconnect stays
        // permanently broken and every sign throws BitboxNotConnected.
        primeFreshChannelHash();

        final cubit = makeCubit();
        addTearDown(cubit.close);

        await waitForState<BitboxCheckHash>(cubit);
        await cubit.confirmPairing();
        expect(cubit.state, isA<BitboxConnected>());

        final credentials = service.getCredentials(
          '0x1111111111111111111111111111111111111111',
        );
        expect(credentials.isConnected, isTrue);

        // Device disappears → observer fires clearBitbox().
        platform.when(
          SimulatedBitboxMethod.getDevices,
          (_) async => const <sdk.BitboxDevice>[],
        );
        await Future<void>.delayed(fastObserverInterval * 4);
        expect(
          credentials.isConnected,
          isFalse,
          reason: 'pre-condition: observer must have cleared the credentials',
        );

        // Device reappears. Drive a fresh pair via the service directly —
        // the cubit's own scan loop was cancelled when it transitioned past
        // BitboxFound, so we exercise the same `init()` re-attach branch the
        // user's "unplug + replug + tap pair again" gesture would hit.
        platform.when(
          SimulatedBitboxMethod.getDevices,
          (_) async => platform.devices,
        );
        final devices = await service.getAllUsbDevices();
        expect(devices, hasLength(1));
        final status = await service.init(devices.single);
        expect(status, isA<Paired>());

        expect(
          credentials.isConnected,
          isTrue,
          reason:
              'the same credentials reference must re-attach on reconnect '
              '(P461 #1 — getCredentials returns the cached instance)',
        );
      },
    );
  });
}
