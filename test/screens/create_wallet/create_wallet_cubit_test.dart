import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_auth_service.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/screens/create_wallet/bloc/create_wallet_cubit.dart';

class _MockWalletService extends Mock implements WalletService {}

class _MockAuthService extends Mock implements DFXAuthService {}

class _FakeSeedDraft extends Fake implements SeedDraft {}

const _testMnemonic = 'test test test test test test test test test test test junk';

void main() {
  late _MockWalletService service;
  late _MockAuthService authService;

  setUpAll(() {
    registerFallbackValue(_FakeSeedDraft());
  });

  setUp(() {
    service = _MockWalletService();
    authService = _MockAuthService();
  });

  group('$CreateWalletCubit', () {
    test('initial state hides the seed and has no draft', () {
      final cubit = CreateWalletCubit(service, authService);

      expect(cubit.state.hideSeed, isTrue);
      expect(cubit.state.draft, isNull);
    });

    test('createWallet stores the newly generated draft in state', () async {
      final draft = SeedDraft(_testMnemonic, name: 'Obi-Wallet-Kenobi');
      when(() => service.generateUncommittedSeedDraft(any())).thenAnswer((_) async => draft);

      final cubit = CreateWalletCubit(service, authService);
      cubit.createWallet();
      await cubit.stream.firstWhere((s) => s.draft != null);

      expect(cubit.state.draft, same(draft));
      verify(() => service.generateUncommittedSeedDraft('Obi-Wallet-Kenobi')).called(1);
      // Pin the disk-side guarantee: the cubit MUST NOT commit on
      // generation — that's `VerifySeedCubit.verify()`'s job, gated on
      // the user actually keeping the seed.
      verifyNever(() => service.commitGeneratedWallet(any()));
    });

    test('createWallet disposes a late draft when the cubit closed first', () async {
      final completer = Completer<SeedDraft>();
      final draft = SeedDraft(_testMnemonic, name: 'Obi-Wallet-Kenobi');
      when(() => service.generateUncommittedSeedDraft(any())).thenAnswer((_) => completer.future);

      final cubit = CreateWalletCubit(service, authService);
      cubit.createWallet();
      await cubit.close();

      completer.complete(draft);
      await Future<void>.delayed(Duration.zero);

      expect(draft.isDisposed, isTrue);
    });

    blocTest<CreateWalletCubit, CreateWalletState>(
      'toggleShowSeed flips hideSeed between true and false',
      build: () => CreateWalletCubit(service, authService),
      act: (cubit) {
        cubit.toggleShowSeed();
        cubit.toggleShowSeed();
      },
      verify: (cubit) {
        expect(cubit.state.hideSeed, isTrue);
      },
    );

    test('toggleShowSeed preserves the draft field', () async {
      final draft = SeedDraft(_testMnemonic);
      when(() => service.generateUncommittedSeedDraft(any())).thenAnswer((_) async => draft);
      final cubit = CreateWalletCubit(service, authService);
      cubit.createWallet();
      await cubit.stream.firstWhere((s) => s.draft != null);

      cubit.toggleShowSeed();

      expect(cubit.state.draft, same(draft));
      expect(cubit.state.hideSeed, isFalse);
    });

    group('app lifecycle', () {
      testWidgets('hidden drops the just-generated mnemonic from cubit state', (tester) async {
        when(
          () => service.generateUncommittedSeedDraft(any()),
        ).thenAnswer((_) async => SeedDraft(_testMnemonic));

        final cubit = CreateWalletCubit(service, authService);
        addTearDown(cubit.close);
        final emissions = <CreateWalletState>[];
        final sub = cubit.stream.listen(emissions.add);
        addTearDown(sub.cancel);

        cubit.createWallet();
        await cubit.stream.firstWhere((s) => s.draft != null);
        final initialDraft = cubit.state.draft!;
        expect(initialDraft.isDisposed, isFalse);
        emissions.clear();

        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        await tester.pump();

        // Pin the BL-018 contract: hidden must dispose the draft AND
        // emit a cleared state. The dispose overwrites the inner
        // mnemonic so a heap walk pre-GC observes spaces in the slot,
        // not the seed.
        expect(
          initialDraft.isDisposed,
          isTrue,
          reason:
              'BL-018: hidden must dispose the draft, not just '
              'drop the cubit reference',
        );
        expect(emissions, isNotEmpty, reason: 'hidden must emit at least the cleared state');
        expect(
          emissions.first.draft,
          isNull,
          reason: 'hidden must drop the draft from cubit state',
        );
        expect(
          emissions.first.hideSeed,
          isTrue,
          reason: 'reset to initial — hideSeed defaults back to true',
        );
      });

      testWidgets('hidden is a no-op when no draft has been generated yet', (tester) async {
        final cubit = CreateWalletCubit(service, authService);
        addTearDown(cubit.close);
        final initial = cubit.state;

        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        await tester.pump();

        expect(
          cubit.state,
          same(initial),
          reason: 'no draft → no emission → reference equality holds',
        );
      });

      const reachableWithoutHidden = <AppLifecycleState>[
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ];
      for (final lifecycle in reachableWithoutHidden) {
        testWidgets('${lifecycle.name} does NOT clear the cubit state — only hidden does', (
          tester,
        ) async {
          final draft = SeedDraft(_testMnemonic);
          when(() => service.generateUncommittedSeedDraft(any())).thenAnswer((_) async => draft);
          final cubit = CreateWalletCubit(service, authService);
          addTearDown(cubit.close);
          cubit.createWallet();
          await cubit.stream.firstWhere((s) => s.draft != null);

          if (lifecycle == AppLifecycleState.resumed) {
            tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
            await tester.pump();
          }
          tester.binding.handleAppLifecycleStateChanged(lifecycle);
          await tester.pump();

          expect(
            cubit.state.draft,
            same(draft),
            reason: '${lifecycle.name} must not drop the draft — only hidden does',
          );
        });
      }

      testWidgets('hidden -> resumed re-generates a fresh draft so the view is not '
          'stuck on the loading indicator', (tester) async {
        var generated = 0;
        when(() => service.generateUncommittedSeedDraft(any())).thenAnswer((_) async {
          generated++;
          return SeedDraft(_testMnemonic, name: 'Obi-Wallet-Kenobi');
        });
        final emissions = <CreateWalletState>[];
        final cubit = CreateWalletCubit(service, authService);
        addTearDown(cubit.close);
        final sub = cubit.stream.listen(emissions.add);
        addTearDown(sub.cancel);

        cubit.createWallet();
        await cubit.stream.firstWhere((s) => s.draft != null);
        final initial = cubit.state.draft;
        expect(generated, 1, reason: 'precondition — initial generation fired once');
        emissions.clear();

        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        await tester.pump();
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pump();

        expect(
          emissions,
          hasLength(2),
          reason: 'hidden must emit cleared-then-regenerated, in that order',
        );
        expect(emissions.first.draft, isNull, reason: 'first emission must be the cleared state');
        expect(
          emissions.last.draft,
          isNotNull,
          reason: 'fresh draft must replace the cleared state',
        );
        expect(
          emissions.last.draft,
          isNot(same(initial)),
          reason: 'a NEW SeedDraft must be generated, not the cleared one',
        );
        expect(
          generated,
          2,
          reason:
              '_dropMnemonic must re-fire generateUncommittedSeedDraft '
              'so the view recovers from the cleared state',
        );
        verifyNever(() => service.commitGeneratedWallet(any()));
      });
    });
  });
}
