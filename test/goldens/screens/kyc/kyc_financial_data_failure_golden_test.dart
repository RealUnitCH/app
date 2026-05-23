import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/kyc/steps/financial_data/subpages/kyc_financial_data_failure_page.dart';

import '../../../helper/helper.dart';

void main() {
  const phoneConstraints = BoxConstraints.tightFor(width: 390, height: 844);

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
