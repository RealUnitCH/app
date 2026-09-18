import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/models/client_policy/real_unit_client_policy.dart';
import 'package:realunit_wallet/packages/utils/marketing_version.dart';
import 'package:realunit_wallet/screens/receive/receive_page.dart';
import 'package:realunit_wallet/screens/receive/widgets/qr_address_widget.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/update_required/bloc/client_policy_cubit.dart';
import 'package:realunit_wallet/setup/routing/routes/app_routes.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';

import '../../helper/helper.dart';

class MockClientPolicyCubit extends MockCubit<ClientPolicyState>
    implements ClientPolicyCubit {}

void main() {
  final AppStore appStore = MockAppStore();
  late MockSettingsBloc settingsBloc;

  setUpAll(() {
    GetIt.instance.registerSingleton<AppStore>(appStore);
  });

  setUp(() {
    settingsBloc = MockSettingsBloc();
    when(() => settingsBloc.state).thenReturn(const SettingsState());
    when(() => appStore.primaryAddress)
        .thenReturn('0x938115b533a0b746428361760a6972dfd06d984a');
    final getIt = GetIt.instance;
    if (getIt.isRegistered<SettingsBloc>()) {
      getIt.unregister<SettingsBloc>();
    }
    getIt.registerSingleton<SettingsBloc>(settingsBloc);
  });

  tearDownAll(() async {
    await GetIt.instance.reset();
  });

  Widget wrapPage(Widget page) => page;

  Finder sendButton() => find.widgetWithText(AppFilledButton, S.current.send);

  group('$ReceivePage', () {
    testWidgets('bottom-sheet variant renders QR and hides Send by default',
        (tester) async {
      await tester.pumpApp(wrapPage(const ReceivePage()));

      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(QRAddressWidget), findsOneWidget);
      expect(sendButton(), findsNothing);
    });

    testWidgets(
      'full-page variant renders AppBar back, QR and hides Send by default',
      (tester) async {
        await tester.pumpApp(wrapPage(const ReceivePage(isBottomSheet: false)));

        expect(find.byType(AppBar), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
        expect(find.byType(QRAddressWidget), findsOneWidget);
        expect(sendButton(), findsNothing);
      },
    );

    testWidgets('shows Send when walletFeatureSend is true', (tester) async {
      when(() => settingsBloc.state)
          .thenReturn(const SettingsState(walletFeatureSend: true));

      await tester.pumpApp(wrapPage(const ReceivePage()));

      expect(find.byType(QRAddressWidget), findsOneWidget);
      expect(sendButton(), findsOneWidget);
    });

    testWidgets('tapping Send pushes the send route', (tester) async {
      when(() => settingsBloc.state)
          .thenReturn(const SettingsState(walletFeatureSend: true));

      final pushedRoutes = <String>[];
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => wrapPage(const ReceivePage()),
          ),
          GoRoute(
            name: AppRoutes.send,
            path: '/send',
            builder: (_, _) {
              pushedRoutes.add(AppRoutes.send);
              return const Scaffold(body: Text('ROUTE:send'));
            },
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(sendButton());
      await tester.pumpAndSettle();

      expect(pushedRoutes, [AppRoutes.send]);
    });

    testWidgets('hides Send when policy becomes hard while mounted',
        (tester) async {
      enableSend();
      final cubit = MockClientPolicyCubit();
      const noneState = ClientPolicyLoaded(
        RealUnitClientPolicy(severity: ClientPolicySeverity.none),
      );
      const hardState = ClientPolicyLoaded(
        RealUnitClientPolicy(severity: ClientPolicySeverity.hard),
      );
      final controller = StreamController<ClientPolicyState>.broadcast();
      addTearDown(controller.close);

      when(() => cubit.severity).thenReturn(ClientPolicySeverity.none);
      whenListen(cubit, controller.stream, initialState: noneState);

      await tester.pumpApp(
        BlocProvider<ClientPolicyCubit>.value(
          value: cubit,
          child: const ReceivePage(),
        ),
      );

      expect(sendButton(), findsOneWidget);

      when(() => cubit.severity).thenReturn(ClientPolicySeverity.hard);
      controller.add(hardState);
      await tester.pump();

      expect(sendButton(), findsNothing);
    });
  });
}
