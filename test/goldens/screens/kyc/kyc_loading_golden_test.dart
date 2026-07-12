import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/kyc/subpages/kyc_loading_page.dart';

import '../../../helper/helper.dart';

void main() {

  group('$KycLoadingPage', () {
    goldenTest(
      'default state, spinner',
      fileName: 'kyc_loading_page_default',
      // CircularProgressIndicator never settles; pump once to capture the
      // initial frame instead of letting pumpAndSettle hang.
      pumpBeforeTest: pumpOnce,
      constraints: phoneConstraints,
      builder: () => wrapForGolden(const KycLoadingPage()),
    );
  });
}
