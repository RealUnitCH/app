import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/widgets/hide_amount_text.dart';

class _MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

void main() {
  late _MockSettingsBloc settings;

  setUp(() {
    settings = _MockSettingsBloc();
  });

  Widget host(HideAmountText child) => MaterialApp(
        home: Scaffold(
          body: BlocProvider<SettingsBloc>.value(value: settings, child: child),
        ),
      );

  group('$HideAmountText (state.hideAmounts=false)', () {
    setUp(() {
      when(() => settings.state).thenReturn(const SettingsState(hideAmounts: false));
    });

    testWidgets('zero amount renders "€ --.-- "', (tester) async {
      await tester.pumpWidget(host(HideAmountText(amount: BigInt.zero)));

      // Default leadingSymbol is '€' (with space), default trailingSymbol is ''
      // (so the text ends with a single space).
      expect(find.text('€ --.-- '), findsOneWidget);
    });

    testWidgets('non-zero amount renders the formatted value', (tester) async {
      await tester.pumpWidget(host(HideAmountText(amount: BigInt.from(123456789))));

      // 18 decimals, 2 fractional digits → 0.00 (truncated).
      expect(find.textContaining('€ 0.00'), findsOneWidget);
    });

    testWidgets('empty leadingSymbol drops the leading "€ " prefix', (tester) async {
      await tester.pumpWidget(
        host(HideAmountText(
          amount: BigInt.from(123456789),
          leadingSymbol: '',
        )),
      );

      // No € anywhere in the rendered tree.
      expect(find.textContaining('€'), findsNothing);
    });

    testWidgets('trailingSymbol is appended after the amount', (tester) async {
      await tester.pumpWidget(
        host(HideAmountText(
          amount: BigInt.from(123456789),
          trailingSymbol: 'CHF',
        )),
      );

      expect(find.textContaining('CHF'), findsOneWidget);
    });
  });

  group('$HideAmountText (state.hideAmounts=true)', () {
    setUp(() {
      when(() => settings.state).thenReturn(const SettingsState(hideAmounts: true));
    });

    testWidgets('renders "€ ***.**" regardless of the amount', (tester) async {
      await tester.pumpWidget(host(HideAmountText(amount: BigInt.from(987654321))));

      expect(find.text('€ ***.**'), findsOneWidget);
    });

    testWidgets('empty leadingSymbol still hides the amount with "***.**"', (tester) async {
      await tester.pumpWidget(
        host(HideAmountText(
          amount: BigInt.from(987654321),
          leadingSymbol: '',
        )),
      );

      expect(find.text('***.**'), findsOneWidget);
    });
  });
}
