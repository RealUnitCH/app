import 'dart:async';

import 'package:bitbox_flutter/bitbox_flutter.dart' as sdk;
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/screens/hardware_wallet/cubit/move_balance_cubit.dart';
import 'package:realunit_wallet/screens/hardware_wallet/hardware_wallet_buy_page.dart';
import 'package:realunit_wallet/screens/hardware_wallet/hardware_wallet_intro_page.dart';
import 'package:realunit_wallet/screens/hardware_wallet/hardware_wallet_paired_page.dart';
import 'package:realunit_wallet/screens/hardware_wallet/hardware_wallet_setup_page.dart';
import 'package:realunit_wallet/screens/hardware_wallet/move_balance_page.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/setup/routing/routes/app_routes.dart';
import 'package:realunit_wallet/setup/routing/routes/settings_routes.dart';
import 'package:realunit_wallet/styles/themes.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';

import '../../helper/helper.dart';

class _MockBitboxService extends Mock implements BitboxService {}

class _MockDfxKycService extends Mock implements DfxKycService {}

class _MockMoveBalanceCubit extends MockCubit<MoveBalanceState>
    implements MoveBalanceCubit {}

const _softwareAddress = '0x0000000000000000000000000000000000000001';

Finder _stickyActions() => find.descendant(
  of: find.byKey(const Key('scrollable_actions_layout.actions_scroll_view')),
  matching: find.byType(AppFilledButton),
);

void main() {
  late MockHomeBloc homeBloc;
  late MockWalletService walletService;
  late MockBitboxWallet bitboxWallet;
  late StreamController<HomeState> homeStates;
  late _MockMoveBalanceCubit moveCubit;

  setUpAll(() {
    registerFallbackValue(const SwitchWalletEvent(0));
    final getIt = GetIt.instance;
    final bitboxService = _MockBitboxService();
    when(() => bitboxService.startScan()).thenAnswer((_) async => false);
    when(() => bitboxService.getAllUsbDevices()).thenAnswer((_) async => <sdk.BitboxDevice>[]);
    getIt.registerSingleton<BitboxService>(bitboxService);
    walletService = MockWalletService();
    getIt.registerSingleton<WalletService>(walletService);
    getIt.registerSingleton<DfxKycService>(_MockDfxKycService());
  });

  tearDownAll(() async => GetIt.instance.reset());

  setUp(() {
    bitboxWallet = MockBitboxWallet();
    when(() => bitboxWallet.walletType).thenReturn(WalletType.bitbox);
    when(() => bitboxWallet.id).thenReturn(2);
    when(() => walletService.listWallets()).thenAnswer((_) async => [bitboxWallet]);

    homeBloc = MockHomeBloc();
    homeStates = StreamController<HomeState>.broadcast();
    addTearDown(homeStates.close);
    final initial = HomeState(
      hasWallet: true,
      openWallet: SoftwareViewWallet(1, 'Software', _softwareAddress),
    );
    whenListen(homeBloc, homeStates.stream, initialState: initial);
    when(() => homeBloc.add(any())).thenAnswer((invocation) {
      final event = invocation.positionalArguments.first;
      if (event is SwitchWalletEvent && event.id == bitboxWallet.id) {
        homeStates.add(HomeState(hasWallet: true, openWallet: bitboxWallet));
      }
    });

    moveCubit = _MockMoveBalanceCubit();
    when(() => moveCubit.confirm()).thenAnswer((_) async {});
    when(() => moveCubit.retryPrepareBitboxToSoftware()).thenAnswer((_) async {});
    when(() => moveCubit.prepareSoftwareToBitbox()).thenAnswer((_) async {});
    when(() => moveCubit.prepareBitboxToSoftware()).thenAnswer((_) async {});
  });

  Widget withHome(Widget child) => BlocProvider<HomeBloc>.value(
    value: homeBloc,
    child: child,
  );

  GoRouter buildRouter(Widget home) => GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => home),
      GoRoute(
        name: SettingsRoutes.hardwareWalletBuy,
        path: '/hardware-wallet-buy',
        builder: (_, _) => const SizedBox.shrink(),
      ),
      GoRoute(
        name: SettingsRoutes.hardwareWalletSetup,
        path: '/hardware-wallet-setup',
        builder: (_, _) => const SizedBox.shrink(),
      ),
      GoRoute(
        name: AppRoutes.kyc,
        path: '/kyc',
        builder: (_, _) => const SizedBox.shrink(),
      ),
      GoRoute(
        name: AppRoutes.dashboard,
        path: '/dashboard',
        builder: (_, _) => const SizedBox.shrink(),
      ),
    ],
  );

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget home,
    MatrixCell cell,
  ) async {
    final router = buildRouter(home);
    addTearDown(router.dispose);
    await tester.binding.setSurfaceSize(cell.mediaQuery.size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MediaQuery(
        data: cell.mediaQuery,
        child: MaterialApp.router(
          routerConfig: router,
          theme: realUnitTheme,
          locale: const Locale('de'),
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<void> expectStickyActionsTappable(
    WidgetTester tester, {
    required Widget Function() page,
    required Finder within,
    required MatrixCell cell,
    required String label,
  }) async {
    await expectNoLayoutOverflow(
      tester,
      () async {
        await pumpScreen(tester, page(), cell);
      },
      reason: 'overflow on $label',
    );

    final count = _stickyActions().evaluate().length;
    expect(count, greaterThan(0), reason: '$label: expected sticky CTA(s)');
    for (var i = 0; i < count; i++) {
      if (i > 0) {
        await pumpScreen(tester, page(), cell);
      }
      await expectFullyTappable(
        tester,
        _stickyActions().at(i),
        within: within,
        reason: '$label: sticky CTA $i not tappable',
      );
    }
  }

  void stubMoveState(MoveBalanceState state) {
    when(() => moveCubit.state).thenReturn(state);
    whenListen(
      moveCubit,
      const Stream<MoveBalanceState>.empty(),
      initialState: state,
    );
  }

  Widget moveBalancePage() => withHome(
    BlocProvider<MoveBalanceCubit>.value(
      value: moveCubit,
      child: const MoveBalanceView(),
    ),
  );

  group('HardwareWalletIntroPage responsive matrix (full device × textScale)', () {
    for (final cell in kFullResponsiveMatrix) {
      testWidgets(cell.id, (tester) async {
        await withTargetPlatform(cell.device.platform, () async {
          await expectStickyActionsTappable(
            tester,
            page: () => withHome(const HardwareWalletIntroPage()),
            within: find.byType(HardwareWalletIntroPage),
            cell: cell,
            label: cell.label,
          );
        });
      });
    }
  });

  group('HardwareWalletBuyPage responsive matrix (full device × textScale)', () {
    for (final cell in kFullResponsiveMatrix) {
      testWidgets(cell.id, (tester) async {
        await withTargetPlatform(cell.device.platform, () async {
          await expectStickyActionsTappable(
            tester,
            page: () => withHome(const HardwareWalletBuyPage()),
            within: find.byType(HardwareWalletBuyPage),
            cell: cell,
            label: cell.label,
          );
        });
      });
    }
  });

  group('HardwareWalletSetupPage responsive matrix (full device × textScale)', () {
    for (final cell in kFullResponsiveMatrix) {
      testWidgets(cell.id, (tester) async {
        await withTargetPlatform(cell.device.platform, () async {
          await expectStickyActionsTappable(
            tester,
            page: () => withHome(const HardwareWalletSetupPage()),
            within: find.byType(HardwareWalletSetupPage),
            cell: cell,
            label: cell.label,
          );
        });
      });
    }
  });

  group('HardwareWalletPairedPage responsive matrix (full device × textScale)', () {
    for (final cell in kFullResponsiveMatrix) {
      testWidgets(cell.id, (tester) async {
        await withTargetPlatform(cell.device.platform, () async {
          await expectStickyActionsTappable(
            tester,
            page: () => withHome(const HardwareWalletPairedPage()),
            within: find.byType(HardwareWalletPairedPage),
            cell: cell,
            label: cell.label,
          );
        });
      });
    }
  });

  group('MoveBalanceView quote ready responsive matrix (full device × textScale)', () {
    for (final cell in kFullResponsiveMatrix) {
      testWidgets(cell.id, (tester) async {
        await withTargetPlatform(cell.device.platform, () async {
          stubMoveState(
            const MoveBalanceQuoteReady(
              direction: MoveBalanceDirection.softwareToBitbox,
              amount: 9,
              networkFeeRealu: 1,
              ethPaysGas: false,
              softwareBalance: 10,
              bitboxBalance: 4,
            ),
          );
          await expectStickyActionsTappable(
            tester,
            page: moveBalancePage,
            within: find.byType(MoveBalanceView),
            cell: cell,
            label: cell.label,
          );
        });
      });
    }
  });

  group('MoveBalanceView need ETH responsive matrix (full device × textScale)', () {
    for (final cell in kFullResponsiveMatrix) {
      testWidgets(cell.id, (tester) async {
        await withTargetPlatform(cell.device.platform, () async {
          stubMoveState(
            const MoveBalanceNeedEth('Insufficient ETH for gas: need 0.01, have 0'),
          );
          await expectStickyActionsTappable(
            tester,
            page: moveBalancePage,
            within: find.byType(MoveBalanceView),
            cell: cell,
            label: cell.label,
          );
        });
      });
    }
  });

  group('MoveBalanceView failure retry responsive matrix (full device × textScale)', () {
    for (final cell in kFullResponsiveMatrix) {
      testWidgets(cell.id, (tester) async {
        await withTargetPlatform(cell.device.platform, () async {
          stubMoveState(
            const MoveBalanceFailure('Broadcast failed', canRetry: true),
          );
          await expectStickyActionsTappable(
            tester,
            page: moveBalancePage,
            within: find.byType(MoveBalanceView),
            cell: cell,
            label: cell.label,
          );
        });
      });
    }
  });

  group('MoveBalanceView failure register-only responsive matrix (full device × textScale)', () {
    for (final cell in kFullResponsiveMatrix) {
      testWidgets(cell.id, (tester) async {
        await withTargetPlatform(cell.device.platform, () async {
          stubMoveState(
            const MoveBalanceFailure('', canRetry: false),
          );
          await expectStickyActionsTappable(
            tester,
            page: moveBalancePage,
            within: find.byType(MoveBalanceView),
            cell: cell,
            label: cell.label,
          );
        });
      });
    }
  });
}
