import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/pay/widgets/pay_result_sheet.dart';

import '../../../helper/helper.dart';

void main() {
  goldenTest(
    'generic failure sheet with close',
    fileName: 'pay_result_sheet_failure',
    constraints: phoneConstraints,
    builder: () => wrapForGolden(
      Builder(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black54,
          bottomSheet: PayResultSheet(
            icon: Icons.error_rounded,
            title: S.of(context).payFailureTitle,
            description: S.of(context).payFailureGeneric,
            closeLabel: S.of(context).close,
            onClose: () {},
          ),
        ),
      ),
    ),
  );

  goldenTest(
    'retry sheet with close and retry',
    fileName: 'pay_process_page_pay_retry',
    constraints: phoneConstraints,
    builder: () => wrapForGolden(
      Builder(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black54,
          bottomSheet: PayResultSheet(
            icon: Icons.replay_rounded,
            title: S.of(context).payRetryTitle,
            description: S.of(context).payRetryTransient,
            closeLabel: S.of(context).close,
            onClose: () {},
            primaryLabel: S.of(context).payRetryButton,
            onPrimary: () {},
          ),
        ),
      ),
    ),
  );
}
