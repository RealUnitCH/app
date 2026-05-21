import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_auth_service.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/packages/wallet/wallet_account.dart';
import 'package:realunit_wallet/screens/create_wallet/bloc/create_wallet_cubit.dart';

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

  group('$CreateWalletCubit', () {
    test('initial state hides the seed and has no wallet', () {
      final cubit = CreateWalletCubit(service, authService);

      expect(cubit.state.hideSeed, isTrue);
      expect(cubit.state.wallet, isNull);
    });

    test('createWallet stores the newly created SoftwareWallet in state', () async {
      final wallet = SoftwareWallet(7, 'Obi-Wallet-Kenobi', _testMnemonic);
      when(() => service.createSeedWallet(any())).thenAnswer((_) async => wallet);

      final cubit = CreateWalletCubit(service, authService);
      cubit.createWallet();
      await cubit.stream.firstWhere((s) => s.wallet != null);

      expect(cubit.state.wallet, same(wallet));
      verify(() => service.createSeedWallet('Obi-Wallet-Kenobi')).called(1);
      verify(() => authService.ensureSignatureFor(wallet.currentAccount)).called(1);
    });

    blocTest<CreateWalletCubit, CreateWalletState>(
      'toggleShowSeed flips hideSeed between true and false',
      build: () => CreateWalletCubit(service, authService),
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
      final cubit = CreateWalletCubit(service, authService);
      cubit.createWallet();
      await cubit.stream.firstWhere((s) => s.wallet != null);

      cubit.toggleShowSeed();

      expect(cubit.state.wallet, same(wallet));
      expect(cubit.state.hideSeed, isFalse);
    });

    // Onboarding-equivalent of #485's app-hidden wallet lock: the freshly
    // generated mnemonic lives in the cubit state (not in `AppStore.wallet`),
    // so `WalletService.lockCurrentWallet` no-op's on this path. Closes #489.
    // `AppLifecycleListener` dispatches through `WidgetsBinding`, so we use
    // `testWidgets` to drive the binding's lifecycle state machine.
    group('app lifecycle', () {
      testWidgets('hidden drops the just-generated mnemonic from cubit state',
          (tester) async {
        final wallet = SoftwareWallet(7, 'Obi-Wallet-Kenobi', _testMnemonic);
        when(() => service.createSeedWallet(any())).thenAnswer((_) async => wallet);

        final cubit = CreateWalletCubit(service, authService);
        addTearDown(cubit.close);
        // Record every emission so we can pin the intermediate cleared
        // state — `_dropMnemonic` re-fires `createWallet()` synchronously
        // after the clear, and the regenerated wallet would otherwise have
        // overwritten the cleared snapshot by the time we sample the
        // current state.
        final emissions = <CreateWalletState>[];
        final sub = cubit.stream.listen(emissions.add);
        addTearDown(sub.cancel);

        cubit.createWallet();
        await cubit.stream.firstWhere((s) => s.wallet != null);
        expect(cubit.state.wallet, same(wallet),
            reason: 'precondition — wallet is in cubit state before hidden fires');
        emissions.clear();

        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        await tester.pump();

        // The first emission after hidden must be the fully cleared state.
        // The reset-to-initial contract is what drops the mnemonic from
        // memory — the regeneration that follows is the UX recovery for
        // the stuck-on-spinner blocker (covered in the next test).
        expect(emissions, isNotEmpty,
            reason: 'hidden must emit at least the cleared state');
        expect(emissions.first.wallet, isNull,
            reason: 'hidden must drop the mnemonic from cubit state');
        expect(emissions.first.hideSeed, isTrue,
            reason: 'reset to initial — hideSeed defaults back to true');
      });

      testWidgets('hidden is a no-op when no wallet has been generated yet',
          (tester) async {
        final cubit = CreateWalletCubit(service, authService);
        addTearDown(cubit.close);
        // No createWallet() call — state is the const initial.
        final initial = cubit.state;

        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        await tester.pump();

        // No emission — the cubit state object is unchanged (no new
        // CreateWalletState was emitted), so the listener stream is empty.
        expect(cubit.state, same(initial),
            reason: 'no wallet → no emission → reference equality holds');
      });

      // Only `hidden` clears — pin every other lifecycle state that the
      // user can realistically hit without going through `hidden` first as
      // a no-op, so a future refactor (e.g. switching to a `switch` with a
      // default-clear) can't silently regress the contract. Flutter's
      // `AppLifecycleListener` enforces a strict transition graph
      // (resumed↔inactive↔hidden↔paused↔detached): from the default
      // `resumed` start state we can reach `inactive` directly, and back
      // to `resumed` via `inactive`. Reaching `paused` / `detached`
      // requires walking through `hidden`, which itself is the trigger we
      // want to keep — those paths are covered by the dedicated `hidden`
      // tests above.
      const reachableWithoutHidden = <AppLifecycleState>[
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ];
      for (final lifecycle in reachableWithoutHidden) {
        testWidgets('${lifecycle.name} does NOT clear the cubit state — only hidden does',
            (tester) async {
          final wallet = SoftwareWallet(7, 'Obi-Wallet-Kenobi', _testMnemonic);
          when(() => service.createSeedWallet(any())).thenAnswer((_) async => wallet);
          final cubit = CreateWalletCubit(service, authService);
          addTearDown(cubit.close);
          cubit.createWallet();
          await cubit.stream.firstWhere((s) => s.wallet != null);

          // resumed is the listener's default starting state — feed an
          // intermediate `inactive` first so the resumed-back-to-resumed
          // transition is valid per the AppLifecycleListener state machine.
          if (lifecycle == AppLifecycleState.resumed) {
            tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
            await tester.pump();
          }
          tester.binding.handleAppLifecycleStateChanged(lifecycle);
          await tester.pump();

          expect(cubit.state.wallet, same(wallet),
              reason: '${lifecycle.name} must not drop the mnemonic — only hidden does');
        });
      }

      // The cubit is built once via `BlocProvider.create` and its
      // constructor cascades a single `..createWallet()` call — that call is
      // NOT re-invoked when the view rebuilds on resume. Without re-firing
      // generation inside `_dropMnemonic`, the user would resume to
      // `state.wallet == null` and the view's `BlocBuilder` would render
      // `CupertinoActivityIndicator` indefinitely (escapable only via the
      // AppBar back button). This pins the resume-re-generation contract.
      testWidgets(
          'hidden → resumed re-generates a fresh wallet so the view is not '
          'stuck on the loading indicator', (tester) async {
        var generated = 0;
        when(() => service.createSeedWallet(any())).thenAnswer((_) async {
          generated++;
          return SoftwareWallet(generated, 'Obi-Wallet-Kenobi', _testMnemonic);
        });
        // Record every emission so we can pin both the intermediate cleared
        // state AND the regenerated state — without the recording, `pump`
        // would drain both the clear and the regenerate microtasks before
        // we sample, hiding the intermediate clear.
        final emissions = <CreateWalletState>[];
        final cubit = CreateWalletCubit(service, authService);
        addTearDown(cubit.close);
        final sub = cubit.stream.listen(emissions.add);
        addTearDown(sub.cancel);

        cubit.createWallet();
        await cubit.stream.firstWhere((s) => s.wallet != null);
        final initial = cubit.state.wallet;
        expect(generated, 1, reason: 'precondition — initial generation fired once');
        emissions.clear();

        // Walk a realistic backgrounding sequence — `resumed` → `inactive`
        // → `hidden` is the order iOS / Android actually emit. The strict
        // `AppLifecycleListener` state machine also requires `inactive`
        // before `hidden` from a `resumed` start. The `inactive` step is a
        // no-op for `_dropMnemonic`; `hidden` is the trigger that clears.
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        await tester.pump();
        // Simulate the user returning from multitasking. Lifecycle ordering
        // is irrelevant to `_dropMnemonic` (it kicks off `createWallet()`
        // synchronously after the clear), but feeding `inactive` → `resumed`
        // here pins the user-observable path end-to-end and stays within
        // the lifecycle state machine.
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pump();

        // Two emissions: the cleared state (drops the mnemonic) followed by
        // the regenerated state (recovers from the spinner).
        expect(emissions, hasLength(2),
            reason: 'hidden must emit cleared-then-regenerated, in that order');
        expect(emissions.first.wallet, isNull,
            reason: 'first emission must be the cleared state');
        expect(emissions.last.wallet, isNotNull,
            reason: 'fresh wallet must replace the cleared state — the view '
                'must not stick on CupertinoActivityIndicator');
        expect(emissions.last.wallet, isNot(same(initial)),
            reason: 'a NEW SoftwareWallet must be generated, not the cleared one');
        expect(generated, 2,
            reason: '_dropMnemonic must re-fire createSeedWallet so the view '
                'recovers from the cleared state');
      });
    });
  });
}
