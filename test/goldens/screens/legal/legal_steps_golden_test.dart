import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/legal/steps/legal_aktionariat_step.dart';
import 'package:realunit_wallet/screens/legal/steps/legal_dfx_step.dart';
import 'package:realunit_wallet/screens/legal/steps/legal_disclaimer_step.dart';
import 'package:realunit_wallet/screens/legal/steps/legal_documents_step.dart';

import '../../../helper/helper.dart';

void main() {
  group('$LegalDisclaimerStep', () {
    goldenTest(
      'first step',
      fileName: 'legal_disclaimer_step_0',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      builder: () => wrapForGolden(
        const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: LegalDisclaimerStep(step: 0),
          ),
        ),
      ),
    );

    goldenTest(
      'second step',
      fileName: 'legal_disclaimer_step_1',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      builder: () => wrapForGolden(
        const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: LegalDisclaimerStep(step: 1),
          ),
        ),
      ),
    );
  });

  group('$LegalDfxStep', () {
    goldenTest(
      'default state',
      fileName: 'legal_dfx_step_default',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      builder: () => wrapForGolden(
        const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: SingleChildScrollView(child: LegalDfxStep()),
          ),
        ),
      ),
    );
  });

  group('$LegalAktionariatStep', () {
    goldenTest(
      'default state',
      fileName: 'legal_aktionariat_step_default',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      builder: () => wrapForGolden(
        const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: SingleChildScrollView(child: LegalAktionariatStep()),
          ),
        ),
      ),
    );
  });

  group('$LegalDocumentsStep', () {
    goldenTest(
      'default state',
      fileName: 'legal_documents_step_default',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      builder: () => wrapForGolden(
        const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: SingleChildScrollView(child: LegalDocumentsStep()),
          ),
        ),
      ),
    );
  });
}
