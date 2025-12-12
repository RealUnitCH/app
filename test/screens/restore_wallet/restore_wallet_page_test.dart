import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
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
import 'package:realunit_wallet/widgets/mnemonic_input_field.dart';

import '../../helper/helper.dart';

class MockRestoreWalletCubit extends MockCubit<RestoreWalletState> implements RestoreWalletCubit {}

class MockValidateSeedCubit extends MockCubit<ValidateSeedState> implements ValidateSeedCubit {}

class MockHomeBloc extends MockBloc<HomeEvent, HomeState> implements HomeBloc {}

class MockWalletService extends Mock implements WalletService {}

class MockWallet extends Mock implements Wallet {}

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
      await tester.pumpApp(RestoreWalletPage());

      expect(find.byType(RestoreWalletView), findsOne);
    });
  });

  group('$RestoreWalletView', () {
    testWidgets('renders initially correctly', (tester) async {
      await tester.pumpApp(buildSubject(RestoreWalletView()));

      expect(find.byType(SvgPicture), findsOne);
      expect(find.byType(RestoreWalletInputField), findsOne);
      expect(find.byType(RestoreWalletButton), findsOne);
    });

    group('$RestoreWalletButton', () {
      testWidgets('is correctly rendered when seed is uncomplete', (tester) async {
        when(() => validateSeedCubit.state).thenReturn(ValidateSeedState.uncomplete);

        await tester.pumpApp(buildSubject(RestoreWalletView()));

        expect(
            find.byWidgetPredicate(
              (Widget widget) =>
                  widget is FilledButton &&
                  widget.enabled == false &&
                  widget.child.runtimeType == Text,
            ),
            findsOne);
      });

      testWidgets('is correctly rendered when seed is complete', (tester) async {
        when(() => validateSeedCubit.state).thenReturn(ValidateSeedState.complete);

        await tester.pumpApp(buildSubject(RestoreWalletView()));

        expect(
            find.byWidgetPredicate(
              (Widget widget) =>
                  widget is FilledButton &&
                  widget.enabled == true &&
                  widget.child.runtimeType == Text,
            ),
            findsOne);
      });

      testWidgets('is correctly rendered when seed is invalid', (tester) async {
        when(() => validateSeedCubit.state).thenReturn(ValidateSeedState.invalid);

        await tester.pumpApp(buildSubject(RestoreWalletView()));

        expect(
            find.byWidgetPredicate(
              (Widget widget) =>
                  widget is FilledButton &&
                  widget.enabled == false &&
                  widget.style?.backgroundColor?.resolve({}) == RealUnitColors.status.red600,
            ),
            findsOne);
      });

      testWidgets('is correctly rendered when seed is valid and restore wallet is loading',
          (tester) async {
        when(() => validateSeedCubit.state).thenReturn(ValidateSeedState.valid);
        when(() => restoreWalletCubit.state).thenReturn(const RestoreWalletState(isLoading: true));

        await tester.pumpApp(buildSubject(RestoreWalletView()));

        expect(
            find.byWidgetPredicate(
              (Widget widget) =>
                  widget is FilledButton &&
                  widget.enabled == false &&
                  widget.style?.backgroundColor?.resolve({}) ==
                      RealUnitColors.realUnitBlue.withValues(alpha: 0.5),
            ),
            findsOne);
        expect(find.byType(CircularProgressIndicator), findsOne);
      });

      testWidgets('is correctly rendered when seed is valid and wallet was restored',
          (tester) async {
        final wallet = MockWallet();

        when(() => validateSeedCubit.state).thenReturn(ValidateSeedState.valid);
        when(() => restoreWalletCubit.state).thenReturn(RestoreWalletState(wallet: wallet));

        await tester.pumpApp(buildSubject(RestoreWalletView()));

        expect(
            find.byWidgetPredicate(
              (Widget widget) =>
                  widget is FilledButton &&
                  widget.enabled == false &&
                  widget.style?.backgroundColor?.resolve({}) == RealUnitColors.green,
            ),
            findsOne);
      });
    });

    group('$RestoreWalletInputField', () {
      testWidgets('is initially correctly rendered', (tester) async {
        when(() => validateSeedCubit.state).thenReturn(ValidateSeedState.uncomplete);

        await tester.pumpApp(buildSubject(RestoreWalletView()));

        expect(
            find.byWidgetPredicate(
              (Widget widget) =>
                  widget is MnemonicInputField && widget.borderColor == RealUnitColors.okker,
            ),
            findsOne);
      });
      testWidgets('is correctly rendered when seed is invalid', (tester) async {
        when(() => validateSeedCubit.state).thenReturn(ValidateSeedState.invalid);

        await tester.pumpApp(buildSubject(RestoreWalletView()));

        expect(
            find.byWidgetPredicate(
              (Widget widget) =>
                  widget is MnemonicInputField &&
                  widget.borderColor == RealUnitColors.status.red600,
            ),
            findsOne);
      });

      testWidgets('is correctly rendered when seed is valid and restore wallet is loading',
          (tester) async {
        when(() => validateSeedCubit.state).thenReturn(ValidateSeedState.valid);
        when(() => restoreWalletCubit.state).thenReturn(const RestoreWalletState(isLoading: true));

        await tester.pumpApp(buildSubject(RestoreWalletView()));

        expect(
            find.byWidgetPredicate(
              (Widget widget) =>
                  widget is MnemonicInputField && widget.borderColor == RealUnitColors.okker,
            ),
            findsOne);
      });

      testWidgets('is correctly rendered when seed is valid and wallet was restored',
          (tester) async {
        final wallet = MockWallet();

        when(() => validateSeedCubit.state).thenReturn(ValidateSeedState.valid);
        when(() => restoreWalletCubit.state).thenReturn(RestoreWalletState(wallet: wallet));

        await tester.pumpApp(buildSubject(RestoreWalletView()));

        expect(
            find.byWidgetPredicate(
              (Widget widget) =>
                  widget is MnemonicInputField && widget.borderColor == RealUnitColors.green,
            ),
            findsOne);
      });
    });

    group('$BlocListener', () {
      testWidgets('calls RestoreWalletCubit.restoreWallet() when seed is valid', (tester) async {
        whenListen(
          validateSeedCubit,
          Stream.fromIterable([ValidateSeedState.valid]),
          initialState: ValidateSeedState.complete,
        );

        await tester.pumpApp(buildSubject(RestoreWalletView()));
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

        await tester.pumpApp(buildSubject(RestoreWalletView()));
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));

        verify(() => homeBloc.add(LoadWalletEvent(wallet))).called(1);
      });
    });
  });
}
