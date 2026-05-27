import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_country_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/widgets/form/country_field.dart';

import '../../helper/pump_app.dart';

class _MockDfxCountryService extends Mock implements DfxCountryService {}

Country _country({
  required int id,
  required String symbol,
  required String name,
  required bool kycAllowed,
}) => Country(
  id: id,
  symbol: symbol,
  name: name,
  kycAllowed: kycAllowed,
);

void main() {
  late _MockDfxCountryService countryService;

  // KYC-allowed: shown for residence and for nationality.
  final ch = _country(
    id: 41,
    symbol: 'CH',
    name: 'Switzerland',
    kycAllowed: true,
  );
  // Also KYC-allowed: a second allowed country.
  final allowed = _country(
    id: 1,
    symbol: 'NA',
    name: 'Nationland',
    kycAllowed: true,
  );
  // Not KYC-allowed: hidden for residence, still shown for nationality.
  final notAllowed = _country(
    id: 2,
    symbol: 'RE',
    name: 'Resland',
    kycAllowed: false,
  );

  setUp(() {
    countryService = _MockDfxCountryService();
    GetIt.instance.registerSingleton<DfxCountryService>(countryService);
  });

  tearDown(() async => GetIt.instance.reset());

  Widget host(Widget child, {GlobalKey<FormState>? formKey}) {
    return Scaffold(
      body: Form(
        key: formKey,
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }

  group('$CountryFieldPurpose', () {
    test('nationality allows every country regardless of kycAllowed', () {
      expect(CountryFieldPurpose.nationality.allows(ch), isTrue);
      expect(CountryFieldPurpose.nationality.allows(notAllowed), isTrue);
    });

    test('residence reads kycAllowed', () {
      expect(CountryFieldPurpose.residence.allows(ch), isTrue);
      expect(CountryFieldPurpose.residence.allows(notAllowed), isFalse);
    });
  });

  group('$CountryField filtering', () {
    testWidgets('nationality purpose shows every country, including non-KYC ones', (
      tester,
    ) async {
      when(
        () => countryService.getAllCountries(),
      ).thenAnswer((_) async => [ch, allowed, notAllowed]);

      await tester.pumpApp(
        host(
          CountryField(
            label: 'Citizenship',
            purpose: CountryFieldPurpose.nationality,
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<Country>));
      await tester.pumpAndSettle();

      expect(find.text('Switzerland'), findsWidgets);
      expect(find.text('Nationland'), findsWidgets);
      expect(find.text('Resland'), findsWidgets);
    });

    testWidgets('residence purpose hides countries with kycAllowed false', (tester) async {
      when(
        () => countryService.getAllCountries(),
      ).thenAnswer((_) async => [ch, allowed, notAllowed]);

      await tester.pumpApp(
        host(
          CountryField(
            label: 'Country',
            purpose: CountryFieldPurpose.residence,
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<Country>));
      await tester.pumpAndSettle();

      expect(find.text('Switzerland'), findsWidgets);
      expect(find.text('Nationland'), findsWidgets);
      expect(find.text('Resland'), findsNothing);
    });
  });

  group('$CountryField no auto-selection', () {
    testWidgets('does not preselect a country and does not fire onChanged', (tester) async {
      when(() => countryService.getAllCountries()).thenAnswer((_) async => [ch, allowed]);
      Country? picked;

      await tester.pumpApp(
        host(
          CountryField(
            label: 'Citizenship',
            purpose: CountryFieldPurpose.nationality,
            onChanged: (c) => picked = c,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(picked, isNull);
      // The hint is visible because no value is selected.
      expect(find.text('Schweiz'), findsOneWidget);
    });

    testWidgets('an untouched field makes the surrounding Form invalid', (tester) async {
      when(() => countryService.getAllCountries()).thenAnswer((_) async => [ch, allowed]);
      final formKey = GlobalKey<FormState>();

      await tester.pumpApp(
        host(
          const CountryField(label: 'Citizenship', purpose: CountryFieldPurpose.nationality),
          formKey: formKey,
        ),
      );
      await tester.pumpAndSettle();

      expect(formKey.currentState!.validate(), isFalse);
    });
  });

  group('$CountryField loading state', () {
    testWidgets('keeps the field present and the Form invalid while loading', (tester) async {
      final completer = Completer<List<Country>>();
      when(() => countryService.getAllCountries()).thenAnswer((_) => completer.future);
      final formKey = GlobalKey<FormState>();

      await tester.pumpApp(
        host(
          const CountryField(label: 'Citizenship', purpose: CountryFieldPurpose.nationality),
          formKey: formKey,
        ),
      );
      // Still loading — no pumpAndSettle.
      await tester.pump();

      expect(find.text('Citizenship'), findsOneWidget);
      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
      expect(formKey.currentState!.validate(), isFalse);

      completer.complete([ch]);
      await tester.pumpAndSettle();
    });
  });

  group('$CountryField initialValue', () {
    testWidgets('preselects the initialValue and fires onChanged once countries load', (
      tester,
    ) async {
      when(() => countryService.getAllCountries()).thenAnswer((_) async => [ch, allowed]);
      Country? picked;

      await tester.pumpApp(
        host(
          CountryField(
            label: 'Citizenship',
            purpose: CountryFieldPurpose.nationality,
            initialValue: ch,
            onChanged: (c) => picked = c,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(picked, ch);
      expect(find.text('Switzerland'), findsOneWidget);
    });

    testWidgets('ignores an initialValue absent from the filtered country list', (tester) async {
      // notAllowed is filtered out for residence purpose; the preselect must not push it back.
      when(
        () => countryService.getAllCountries(),
      ).thenAnswer((_) async => [ch, notAllowed]);
      Country? picked;

      await tester.pumpApp(
        host(
          CountryField(
            label: 'Country',
            purpose: CountryFieldPurpose.residence,
            initialValue: notAllowed,
            onChanged: (c) => picked = c,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(picked, isNull);
    });
  });

  group('$CountryField error state', () {
    testWidgets('keeps the field present, the Form invalid, and offers a retry', (tester) async {
      var calls = 0;
      when(() => countryService.getAllCountries()).thenAnswer((_) async {
        calls++;
        if (calls == 1) throw Exception('network down');
        return [ch];
      });
      final formKey = GlobalKey<FormState>();

      await tester.pumpApp(
        host(
          const CountryField(label: 'Citizenship', purpose: CountryFieldPurpose.nationality),
          formKey: formKey,
        ),
      );
      await tester.pumpAndSettle();

      // The field is present, the raw exception is not leaked, the Form is invalid.
      expect(find.text('Citizenship'), findsOneWidget);
      expect(find.textContaining('network down'), findsNothing);
      expect(formKey.currentState!.validate(), isFalse);
      expect(find.byType(DropdownButtonFormField<Country>), findsNothing);

      // Retry re-runs the load and recovers into the dropdown.
      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();

      expect(calls, 2);
      expect(find.byType(DropdownButtonFormField<Country>), findsOneWidget);
    });
  });
}
