import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/screens/legal/subpages/legal_document_page.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';

import '../../../helper/helper.dart';

void main() {
  late MockSettingsBloc settingsBloc;

  setUp(() {
    settingsBloc = MockSettingsBloc();
    when(() => settingsBloc.state).thenReturn(const SettingsState());
  });

  Widget buildSubject() => BlocProvider<SettingsBloc>.value(
        value: settingsBloc,
        child: const LegalDocumentPage(
          params: LegalDocumentParams(
            title: 'Terms',
            assetBaseName: 'terms',
          ),
        ),
      );

  group('$LegalDocumentPage', () {
    goldenTest(
      'initial state before markdown loads',
      fileName: 'legal_document_page_default',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      builder: () => wrapForGolden(buildSubject()),
    );
  });
}
