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

  goldenTest(
    'insufficient-eth failure sheet with close',
    fileName: 'pay_result_sheet_failure_insufficient_eth',
    constraints: phoneConstraints,
    builder: () => wrapForGolden(
      Builder(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black54,
          bottomSheet: PayResultSheet(
            icon: Icons.error_rounded,
            title: S.of(context).payFailureTitle,
            description: S.of(context).payFailureInsufficientEth,
            closeLabel: S.of(context).close,
            onClose: () {},
          ),
        ),
      ),
    ),
  );

  goldenTest(
    'signature-unsupported failure sheet with close',
    fileName: 'pay_result_sheet_failure_signature_unsupported',
    constraints: phoneConstraints,
    builder: () => wrapForGolden(
      Builder(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black54,
          bottomSheet: PayResultSheet(
            icon: Icons.error_rounded,
            title: S.of(context).payFailureTitle,
            description: S.of(context).payFailureSignatureUnsupported,
            closeLabel: S.of(context).close,
            onClose: () {},
          ),
        ),
      ),
    ),
  );

  goldenTest(
    'pay-unavailable failure sheet with close',
    fileName: 'pay_result_sheet_failure_pay_unavailable',
    constraints: phoneConstraints,
    builder: () => wrapForGolden(
      Builder(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black54,
          bottomSheet: PayResultSheet(
            icon: Icons.error_rounded,
            title: S.of(context).payFailureTitle,
            description: S.of(context).payFailurePayUnavailable,
            closeLabel: S.of(context).close,
            onClose: () {},
          ),
        ),
      ),
    ),
  );

  goldenTest(
    'bitbox-required failure sheet with close',
    fileName: 'pay_result_sheet_failure_bitbox_required',
    constraints: phoneConstraints,
    builder: () => wrapForGolden(
      Builder(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black54,
          bottomSheet: PayResultSheet(
            icon: Icons.error_rounded,
            title: S.of(context).payFailureTitle,
            description: S.of(context).payFailureBitboxRequired,
            closeLabel: S.of(context).close,
            onClose: () {},
          ),
        ),
      ),
    ),
  );
}
