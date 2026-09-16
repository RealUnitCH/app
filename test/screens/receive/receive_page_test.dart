import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/screens/receive/receive_page.dart';
import 'package:realunit_wallet/screens/receive/widgets/qr_address_widget.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/setup/routing/routes/app_routes.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';

import '../../helper/helper.dart';

void main() {
  final AppStore appStore = MockAppStore();
  late MockSettingsBloc settingsBloc;

  setUpAll(() {
    GetIt.instance.registerSingleton<AppStore>(appStore);
    settingsBloc = MockSettingsBloc();
    GetIt.instance.registerSingleton<SettingsBloc>(settingsBloc);
  });

  setUp(() {
    when(() => appStore.primaryAddress)
        .thenReturn('0x938115b533a0b746428361760a6972dfd06d984a');
    when(() => settingsBloc.state).thenReturn(const SettingsState());
  });

  tearDownAll(() async {
    await GetIt.instance.reset();
  });

  Finder sendButton() => find.widgetWithText(AppFilledButton, S.current.send);

  void enableSend() {
    when(() => settingsBloc.state).thenReturn(
      const SettingsState(
        insiderFeaturesUnlocked: true,
        insiderSendEnabled: true,
      ),
    );
  }

  group('$ReceivePage', () {
    testWidgets('default state renders QR and hides Send', (tester) async {
      await tester.pumpApp(const ReceivePage());

      expect(find.byType(QRAddressWidget), findsOneWidget);
      expect(sendButton(), findsNothing);
    });

    testWidgets('unlocked=false AND send=true: Send absent', (tester) async {
      when(() => settingsBloc.state).thenReturn(
        const SettingsState(insiderSendEnabled: true),
      );
      await tester.pumpApp(const ReceivePage());

      expect(find.byType(QRAddressWidget), findsOneWidget);
      expect(sendButton(), findsNothing);
    });

    testWidgets('unlocked=true AND send=false: Send absent', (tester) async {
      when(() => settingsBloc.state).thenReturn(
        const SettingsState(insiderFeaturesUnlocked: true),
      );
      await tester.pumpApp(const ReceivePage());

      expect(find.byType(QRAddressWidget), findsOneWidget);
      expect(sendButton(), findsNothing);
    });

    testWidgets('bottom-sheet variant renders QR and Send', (tester) async {
      enableSend();
      await tester.pumpApp(const ReceivePage());

      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(QRAddressWidget), findsOneWidget);
      expect(sendButton(), findsOneWidget);
    });

    testWidgets('full-page variant renders AppBar back, QR and Send',
        (tester) async {
      enableSend();
      await tester.pumpApp(const ReceivePage(isBottomSheet: false));

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      expect(find.byType(QRAddressWidget), findsOneWidget);
      expect(sendButton(), findsOneWidget);
    });

    testWidgets('tapping Send pushes the send route', (tester) async {
      enableSend();
      final pushedRoutes = <String>[];
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const ReceivePage(),
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
  });
}
