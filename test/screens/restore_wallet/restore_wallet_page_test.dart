import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/restore_wallet/cubit/restore_wallet/restore_wallet_cubit.dart';
import 'package:realunit_wallet/screens/restore_wallet/cubit/validate_seed/validate_seed_cubit.dart';
import 'package:realunit_wallet/screens/restore_wallet/restore_wallet_page.dart';
import 'package:realunit_wallet/screens/restore_wallet/restore_wallet_view.dart';
import 'package:realunit_wallet/screens/restore_wallet/widgets/restore_wallet_button.dart';
import 'package:realunit_wallet/screens/restore_wallet/widgets/restore_wallet_input_field.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/mnemonic_field.dart';

import '../../helper/helper.dart';

class MockRestoreWalletCubit extends MockCubit<RestoreWalletState> implements RestoreWalletCubit {}

class MockValidateSeedCubit extends MockCubit<ValidateSeedState> implements ValidateSeedCubit {}

class MockHomeBloc extends MockBloc<HomeEvent, HomeState> implements HomeBloc {}

class MockWalletService extends Mock implements WalletService {}

class MockDfxKycService extends Mock implements DfxKycService {}

class MockWallet extends Mock implements SoftwareWallet {}

void main() {
  late RestoreWalletCubit restoreWalletCubit;
  late ValidateSeedCubit validateSeedCubit;
  late HomeBloc homeBloc;

  setUp(() {
    restoreWalletCubit = MockRestoreWalletCubit();
    validateSeedCubit = MockValidateSeedCubit();
    homeBloc = MockHomeBloc();

    when(() => restoreWalletCubit.state).thenReturn(const RestoreWalletState());
    when(() => validateSeedCubit.state).thenReturn(ValidateSeedState.uncomplete);
  });

  void setupDependencyInjection() {
    final getIt = GetIt.instance;
    getIt.registerSingleton<WalletService>(MockWalletService());
    // RestoreWalletCubit pulls a DFXAuthService (smallest concrete: DfxKycService)
    // to pre-warm the auth signature after persisting the mnemonic.
    getIt.registerSingleton<DfxKycService>(MockDfxKycService());
  }

  setUpAll(() {
    setupDependencyInjection();
  });

  tearDownAll(() async => await GetIt.instance.reset());

  Widget buildSubject(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: homeBloc),
        BlocProvider.value(value: restoreWalletCubit),
        BlocProvider.value(value: validateSeedCubit),
      ],
      child: child,
    );
  }

  group('$RestoreWalletPage', () {
    testWidgets('renders $RestoreWalletView', (tester) async {
      await tester.pumpApp(const RestoreWalletPage());

      expect(find.byType(RestoreWalletView), findsOne);
    });
  });

  group('$RestoreWalletView', () {
    testWidgets('renders initially correctly', (tester) async {
      await tester.pumpApp(buildSubject(const RestoreWalletView()));

      expect(
        find.byWidgetPredicate((Widget widget) => widget is SvgPicture && widget.height == 124),
        findsOne,
      );
      expect(find.byType(RestoreWalletInputField), findsOne);
      expect(find.byType(RestoreWalletButton), findsOne);
    });

    // The restore screen is where the user types their existing 12-word
    // recovery phrase, so it handles real seed material like the sibling seed
    // screens. It must block screenshots + the app-switcher snapshot on init
    // and re-enable them on dispose so it never lands in the recents thumbnail
    // or a screen recording.
    testWidgets('disables screenshots on init and re-enables on dispose', (tester) async {
      const channel = MethodChannel('com.flutterplaza.no_screenshot_methods');
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (call) async {
          calls.add(call.method);
          return true;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null),
      );

      await tester.pumpApp(buildSubject(const RestoreWalletView()));
      expect(
        calls,
        contains('screenshotOff'),
        reason: 'the restore screen handles real seed words and must block screenshots on init',
      );

      // Replace the screen so RestoreWalletView is disposed.
      await tester.pumpApp(buildSubject(const SizedBox.shrink()));
      expect(
        calls,
        contains('screenshotOn'),
        reason: 'leaving the restore screen must re-enable screenshots',
      );
    });

    group('$RestoreWalletButton', () {
      testWidgets('is correctly rendered when seed is uncomplete', (tester) async {
        when(() => validateSeedCubit.state).thenReturn(ValidateSeedState.uncomplete);

        await tester.pumpApp(buildSubject(const RestoreWalletView()));

        expect(
          find.byWidgetPredicate(
            (Widget widget) =>
                widget is FilledButton &&
                widget.enabled == false &&
                widget.child.runtimeType == Text,
          ),
          findsOne,
        );
      });

      testWidgets('is correctly rendered when seed is complete', (tester) async {
        when(() => validateSeedCubit.state).thenReturn(ValidateSeedState.complete);

        await tester.pumpApp(buildSubject(const RestoreWalletView()));

        expect(
          find.byWidgetPredicate(
            (Widget widget) =>
                widget is FilledButton &&
                widget.enabled == true &&
                widget.child.runtimeType == Text,
          ),
          findsOne,
        );
      });

      testWidgets('is correctly rendered when seed is invalid', (tester) async {
        when(() => validateSeedCubit.state).thenReturn(ValidateSeedState.invalid);

        await tester.pumpApp(buildSubject(const RestoreWalletView()));

        expect(
          find.byWidgetPredicate(
            (Widget widget) =>
                widget is FilledButton &&
                widget.enabled == false &&
                widget.style?.backgroundColor?.resolve({}) == RealUnitColors.status.red600,
          ),
          findsOne,
        );
      });

      testWidgets('is correctly rendered when seed is valid and restore wallet is loading', (
        tester,
      ) async {
        when(() => validateSeedCubit.state).thenReturn(ValidateSeedState.valid);
        when(() => restoreWalletCubit.state).thenReturn(const RestoreWalletState(isLoading: true));

        await tester.pumpApp(buildSubject(const RestoreWalletView()));

        expect(
          find.byWidgetPredicate(
            (Widget widget) =>
                widget is FilledButton &&
                widget.enabled == false &&
                widget.style?.backgroundColor?.resolve({}) ==
                    RealUnitColors.realUnitBlue.withValues(alpha: 0.5),
          ),
          findsOne,
        );
        expect(find.byType(CupertinoActivityIndicator), findsOne);
      });

      testWidgets('is correctly rendered when seed is valid and wallet was restored', (
        tester,
      ) async {
        final wallet = MockWallet();

        when(() => validateSeedCubit.state).thenReturn(ValidateSeedState.valid);
        when(() => restoreWalletCubit.state).thenReturn(RestoreWalletState(wallet: wallet));

        await tester.pumpApp(buildSubject(const RestoreWalletView()));

        expect(
          find.byWidgetPredicate(
            (Widget widget) =>
                widget is FilledButton &&
                widget.enabled == false &&
                widget.style?.backgroundColor?.resolve({}) == RealUnitColors.green,
          ),
          findsOne,
        );
      });

      testWidgets(
          'offers a tappable retry (not a dead spinner) when restore failed '
          '(issue #657 P1 B1)', (tester) async {
        when(() => validateSeedCubit.state).thenReturn(ValidateSeedState.valid);
        when(() => restoreWalletCubit.state)
            .thenReturn(const RestoreWalletState(hasError: true));

        await tester.pumpApp(buildSubject(const RestoreWalletView()));

        // Paste a seed into the first cell; the paste handler spreads it over all 12.
        const seed = 'test test test test test test test test test test test junk';
        await tester.enterText(find.byType(TextField).first, seed);
        await tester.pump();

        final button = find.descendant(
          of: find.byType(RestoreWalletButton),
          matching: find.byType(FilledButton),
        );
        // Not stuck on the loading spinner; the button is interactive.
        expect(find.byType(CupertinoActivityIndicator), findsNothing);
        expect(tester.widget<FilledButton>(button).enabled, isTrue);

        // Tapping it retries the restore with the exact seed that was entered.
        await tester.tap(button);
        await tester.pump();
        verify(() => restoreWalletCubit.restoreWallet(seed)).called(1);
      });
    });

    group('$RestoreWalletInputField', () {
      testWidgets('is initially correctly rendered', (tester) async {
        when(() => validateSeedCubit.state).thenReturn(ValidateSeedState.uncomplete);

        await tester.pumpApp(buildSubject(const RestoreWalletView()));

        expect(
          find.byWidgetPredicate(
            (Widget widget) =>
                widget is MnemonicInputField && widget.borderColor == RealUnitColors.okker,
          ),
          findsOne,
        );
      });
      testWidgets('is correctly rendered when seed is invalid', (tester) async {
        when(() => validateSeedCubit.state).thenReturn(ValidateSeedState.invalid);

        await tester.pumpApp(buildSubject(const RestoreWalletView()));

        expect(
          find.byWidgetPredicate(
            (Widget widget) =>
                widget is MnemonicInputField && widget.borderColor == RealUnitColors.status.red600,
          ),
          findsOne,
        );
      });

      testWidgets('is correctly rendered when seed is valid and restore wallet is loading', (
        tester,
      ) async {
        when(() => validateSeedCubit.state).thenReturn(ValidateSeedState.valid);
        when(() => restoreWalletCubit.state).thenReturn(const RestoreWalletState(isLoading: true));

        await tester.pumpApp(buildSubject(const RestoreWalletView()));

        expect(
          find.byWidgetPredicate(
            (Widget widget) =>
                widget is MnemonicInputField && widget.borderColor == RealUnitColors.okker,
          ),
          findsOne,
        );
      });

      testWidgets('is correctly rendered when seed is valid and wallet was restored', (
        tester,
      ) async {
        final wallet = MockWallet();

        when(() => validateSeedCubit.state).thenReturn(ValidateSeedState.valid);
        when(() => restoreWalletCubit.state).thenReturn(RestoreWalletState(wallet: wallet));

        await tester.pumpApp(buildSubject(const RestoreWalletView()));

        expect(
          find.byWidgetPredicate(
            (Widget widget) =>
                widget is MnemonicInputField && widget.borderColor == RealUnitColors.green,
          ),
          findsOne,
        );
      });
    });

    group('$BlocListener', () {
      testWidgets('calls RestoreWalletCubit.restoreWallet() when seed is valid', (tester) async {
        whenListen(
          validateSeedCubit,
          Stream.fromIterable([ValidateSeedState.valid]),
          initialState: ValidateSeedState.complete,
        );

        await tester.pumpApp(buildSubject(const RestoreWalletView()));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        verify(
          () => restoreWalletCubit.restoreWallet(any()),
        ).called(1);
      });

      testWidgets('sends $HomeEvent when $RestoreWalletState has wallet restored', (tester) async {
        final wallet = MockWallet();

        whenListen(
          restoreWalletCubit,
          Stream.fromIterable([RestoreWalletState(wallet: wallet)]),
          initialState: const RestoreWalletState(),
        );

        await tester.pumpApp(buildSubject(const RestoreWalletView()));
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));

        verify(() => homeBloc.add(LoadWalletEvent(wallet))).called(1);
      });
    });
  });
}
