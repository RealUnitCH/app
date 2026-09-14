import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/referral/referral_bind_error_dialog.dart';
import 'package:realunit_wallet/screens/referral/referral_error_message.dart';

import '../../../helper/helper.dart';

Widget _overlay(String token) {
  return wrapForGolden(
    ColoredBox(
      color: const Color(0x8A000000),
      child: Center(child: ReferralBindErrorDialog(token: token)),
    ),
  );
}

void main() {
  group('$ReferralBindErrorDialog', () {
    goldenTest(
      'invalid or expired',
      fileName: 'referral_bind_error_invalid',
      constraints: phoneConstraints,
      builder: () => _overlay(referralInvalidMessage),
    );

    goldenTest(
      'already registered (first RealUnit purchase done)',
      fileName: 'referral_bind_error_already_registered',
      constraints: phoneConstraints,
      builder: () => _overlay(referralAlreadyRegisteredMessage),
    );

    goldenTest(
      'already bound',
      fileName: 'referral_bind_error_already_bound',
      constraints: phoneConstraints,
      builder: () => _overlay(referralAlreadyBoundMessage),
    );

    goldenTest(
      'self-referral',
      fileName: 'referral_bind_error_self_referral',
      constraints: phoneConstraints,
      builder: () => _overlay(referralSelfReferralMessage),
    );

    goldenTest(
      'spent',
      fileName: 'referral_bind_error_spent',
      constraints: phoneConstraints,
      builder: () => _overlay(referralSpentMessage),
    );
  });
}
