import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/terms/terms_page.dart';

import '../../helper/helper.dart';

class MockHomeBloc extends MockBloc<HomeEvent, HomeState> implements HomeBloc {}

void main() {
  late HomeBloc homeBloc;

  setUp(() {
    homeBloc = MockHomeBloc();
  });

  Widget buildSubject() {
    return BlocProvider.value(
      value: homeBloc,
      child: const TermsPage(),
    );
  }

  group('$TermsPage', () {
    testWidgets('renders initially correctly', (tester) async {
      await tester.pumpApp(buildSubject());

      expect(find.byType(Image), findsOne);

      final filledButtonFinder = find.byType(FilledButton);
      final filledButtonWidget = tester.widget(filledButtonFinder) as FilledButton;
      expect(filledButtonFinder, findsOne);
      expect(filledButtonWidget.enabled, isTrue);
      expect(find.text(S.current.start), findsOne);
    });

    testWidgets('continue button dispatches AcceptSoftwareTermsEvent', (tester) async {
      await tester.pumpApp(buildSubject());

      await tester.tap(find.byType(FilledButton));

      verify(() => homeBloc.add(const AcceptSoftwareTermsEvent())).called(1);
    });
  });
}
