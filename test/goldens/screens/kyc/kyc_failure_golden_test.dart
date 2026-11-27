import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/kyc/subpages/kyc_failure_page.dart';

import '../../../helper/helper.dart';

void main() {

  group('$KycFailurePage', () {
    goldenTest(
      'default state with error message',
      fileName: 'kyc_failure_page_default',
      constraints: phoneConstraints,
      builder: () => wrapForGolden(
        const KycFailurePage(message: 'Something went wrong'),
      ),
    );

    // KycTimedOut → KycViewManager shows the localized `registerEmailTimeout`
    // sentence on the same page.
    goldenTest(
      'timeout — localized timeout sentence',
      fileName: 'kyc_failure_page_timeout',
      constraints: phoneConstraints,
      builder: () => wrapForGolden(
        Builder(
          builder: (context) => KycFailurePage(message: S.of(context).registerEmailTimeout),
        ),
      ),
    );
  });
}
