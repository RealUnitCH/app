import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/kyc/steps/financial_data/subpages/kyc_financial_data_failure_page.dart';
import 'package:realunit_wallet/screens/kyc/steps/financial_data/subpages/kyc_financial_data_loading_page.dart';
import 'package:realunit_wallet/styles/colors.dart';

import '../../../../../helper/helper.dart';

void main() {
  group('$KycFinancialDataLoadingPage', () {
    testWidgets('renders a centered CupertinoActivityIndicator', (tester) async {
      await tester.pumpApp(const KycFinancialDataLoadingPage());

      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    });
  });

  group('$KycFinancialDataFailurePage', () {
    testWidgets('renders the passed message', (tester) async {
      await tester.pumpApp(
        const KycFinancialDataFailurePage(message: 'Something went wrong'),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('renders the message in the status-red foreground', (tester) async {
      await tester.pumpApp(
        const KycFinancialDataFailurePage(message: 'Boom'),
      );

      final text = tester.widget<Text>(find.text('Boom'));
      expect(text.style?.color, RealUnitColors.status.red600);
    });
  });
}
