import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/kyc/steps/financial_data/subpages/kyc_financial_data_failure_page.dart';

import '../../../helper/helper.dart';

void main() {

  group('$KycFinancialDataFailurePage', () {
    goldenTest(
      'default state with error message',
      fileName: 'kyc_financial_data_failure_page_default',
      constraints: phoneConstraints,
      builder: () => wrapForGolden(
        const KycFinancialDataFailurePage(message: 'Something went wrong'),
      ),
    );
  });
}
