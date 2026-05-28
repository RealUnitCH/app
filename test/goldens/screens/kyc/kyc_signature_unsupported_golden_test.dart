import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/kyc/steps/signature_unsupported/kyc_signature_unsupported_page.dart';

import '../../../helper/helper.dart';

void main() {
  group('$KycSignatureUnsupportedPage', () {
    goldenTest(
      'default state — debug wallet cannot sign',
      fileName: 'kyc_signature_unsupported_page_default',
      constraints: phoneConstraints,
      builder: () => wrapForGolden(
        const KycSignatureUnsupportedPage(),
      ),
    );
  });
}
