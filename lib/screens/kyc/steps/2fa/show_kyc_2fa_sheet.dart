import 'package:flutter/material.dart';
import 'package:realunit_wallet/screens/kyc/steps/2fa/kyc_2fa_page.dart';

Future<void> showKyc2FaSheet(
  BuildContext context, {
  required VoidCallback onVerified,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => Kyc2FaPage(
      onVerified: () {
        Navigator.of(sheetContext).pop();
        onVerified();
      },
    ),
  );
}
