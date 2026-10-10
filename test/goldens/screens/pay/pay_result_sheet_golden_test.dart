import 'package:flutter/material.dart';
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

}
