import 'package:alchemist/alchemist.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/kyc/steps/financial_data/subpages/kyc_financial_data_loading_page.dart';

import '../../../helper/helper.dart';

void main() {

  group('$KycFinancialDataLoadingPage', () {
    goldenTest(
      'default loading state',
      fileName: 'kyc_financial_data_loading_page_default',
      // CircularProgressIndicator never settles; pump once to capture the
      // initial frame instead of letting pumpAndSettle hang.
      pumpBeforeTest: pumpOnce,
      constraints: phoneConstraints,
      builder: () => wrapForGolden(const KycFinancialDataLoadingPage()),
    );
  });
}
