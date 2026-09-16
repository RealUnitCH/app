import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/settings_insider/settings_insider_page.dart';

import '../../helper/helper.dart';

void main() {
  late MockSettingsBloc settingsBloc;

  setUp(() async {
    await GetIt.instance.reset();
    settingsBloc = MockSettingsBloc();
    when(() => settingsBloc.state).thenReturn(const SettingsState());
    GetIt.instance.registerSingleton<SettingsBloc>(settingsBloc);
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  Future<void> pumpPage(WidgetTester tester) {
    return tester.pumpWidget(wrapForGolden(const SettingsInsiderPage()));
  }

  testWidgets('AppBar title is settingsInsiderFeatures', (tester) async {
    await pumpPage(tester);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text(S.current.settingsInsiderFeatures),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Pay row and Switch are present', (tester) async {
    await pumpPage(tester);
    await tester.pumpAndSettle();

    expect(find.text(S.current.pay), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
  });

  testWidgets('tapping Pay text dispatches SetInsiderPayEnabledEvent(true) once', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text(S.current.pay));
    await tester.pump();

    verify(() => settingsBloc.add(const SetInsiderPayEnabledEvent(true))).called(1);
  });

  testWidgets('tapping the Pay Switch dispatches SetInsiderPayEnabledEvent(true) once', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.pumpAndSettle();

    // Switch is IgnorePointer (row owns the tap); the hit must pass through.
    await tester.tap(find.byType(Switch), warnIfMissed: false);
    await tester.pump();

    verify(() => settingsBloc.add(const SetInsiderPayEnabledEvent(true))).called(1);
  });

  testWidgets('when insiderPayEnabled is true, Switch.value is true', (tester) async {
    when(() => settingsBloc.state)
        .thenReturn(const SettingsState(insiderPayEnabled: true));

    await pumpPage(tester);
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
  });
}
