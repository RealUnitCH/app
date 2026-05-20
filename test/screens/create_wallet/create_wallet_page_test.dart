import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/screens/create_wallet/bloc/create_wallet_cubit.dart';
import 'package:realunit_wallet/screens/create_wallet/create_wallet_page.dart';
import 'package:realunit_wallet/screens/create_wallet/create_wallet_view.dart';
import 'package:realunit_wallet/widgets/seed_blur_card.dart';

import '../../helper/pump_app.dart';

class MockCreateWalletCubit extends MockCubit<CreateWalletState> implements CreateWalletCubit {}

class MockWalletService extends Mock implements WalletService {}

class MockDfxKycService extends Mock implements DfxKycService {}

class MockWallet extends Mock implements SoftwareWallet {}

void main() {
  late CreateWalletCubit createWalletCubit;

  setUp(() {
    createWalletCubit = MockCreateWalletCubit();

    when(() => createWalletCubit.state).thenReturn(const CreateWalletState());
  });

  void setupDependencyInjection() {
    final getIt = GetIt.instance;
    final walletService = MockWalletService();
    when(() => walletService.createSeedWallet(any())).thenAnswer((_) => Future.value(MockWallet()));
    getIt.registerSingleton<WalletService>(walletService);
    // `CreateWalletPage.build` reaches for `DfxKycService` to pass to the cubit
    // as a transport for `ensureSignatureFor`. Register a stub so DI resolves.
    getIt.registerSingleton<DfxKycService>(MockDfxKycService());
  }

  setUpAll(() {
    setupDependencyInjection();
  });

  tearDownAll(() async => await GetIt.instance.reset());

  Widget buildSubject(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: createWalletCubit),
      ],
      child: child,
    );
  }

  group('$CreateWalletPage', () {
    testWidgets('renders $CreateWalletView', (tester) async {
      await tester.pumpApp(const CreateWalletPage());

      expect(find.byType(CreateWalletView), findsOne);
    });
  });

  group('$CreateWalletView', () {
    testWidgets('is rendered initially correctly', (tester) async {
      await tester.pumpApp(buildSubject(const CreateWalletView()));

      expect(find.byType(CupertinoActivityIndicator), findsOne);
    });

    testWidgets('is rendered correctly when wallet available', (tester) async {
      final wallet = MockWallet();
      when(() => wallet.seed).thenReturn(
        'cheese trigger cannon mention judge hire snack sustain annual predict illness celery',
      );
      when(() => createWalletCubit.state).thenReturn(CreateWalletState(wallet: wallet));

      await tester.pumpApp(buildSubject(const CreateWalletView()));

      expect(
        find.byWidgetPredicate((widget) => widget is SvgPicture && widget.width == 124),
        findsOne,
      );
      expect(find.byType(SeedBlurCard), findsOne);
      expect(find.byType(FilledButton), findsOne);
    });

    group('$SeedBlurCard', () {
      testWidgets('is blurred', (tester) async {
        final wallet = MockWallet();
        when(() => wallet.seed).thenReturn(
          'cheese trigger cannon mention judge hire snack sustain annual predict illness celery',
        );
        when(
          () => createWalletCubit.state,
        ).thenReturn(CreateWalletState(wallet: wallet, hideSeed: true));

        await tester.pumpApp(buildSubject(const CreateWalletView()));

        final seedBlurCardWidget = tester.widget<SeedBlurCard>(find.byType(SeedBlurCard));
        expect(seedBlurCardWidget.blur, isTrue);
      });
    });

    testWidgets('is unblurred', (tester) async {
      final wallet = MockWallet();
      when(() => wallet.seed).thenReturn(
        'cheese trigger cannon mention judge hire snack sustain annual predict illness celery',
      );
      when(
        () => createWalletCubit.state,
      ).thenReturn(CreateWalletState(wallet: wallet, hideSeed: false));

      await tester.pumpApp(buildSubject(const CreateWalletView()));

      final seedBlurCardWidget = tester.widget<SeedBlurCard>(find.byType(SeedBlurCard));
      expect(seedBlurCardWidget.blur, isFalse);
    });
  });
}
