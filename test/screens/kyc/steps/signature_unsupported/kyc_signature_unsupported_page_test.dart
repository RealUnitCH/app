import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/kyc/steps/signature_unsupported/kyc_signature_unsupported_page.dart';

import '../../../../helper/pump_app.dart';

void main() {
  group('$KycSignatureUnsupportedPage', () {
    testWidgets('renders title, description, and info icon', (tester) async {
      await tester.pumpApp(const KycSignatureUnsupportedPage());

      // Two title occurrences: AppBar + headline body Text.
      expect(find.text(S.current.kycSignatureUnsupportedTitle), findsNWidgets(2));
      expect(find.text(S.current.kycSignatureUnsupportedDescription), findsOne);
      expect(find.byIcon(Icons.info_outline), findsOne);
    });
  });
}
