import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/styles/colors.dart';

/// Spinner shown in place of the number pad while an async PIN operation runs
/// (verifying an entered PIN, or writing the freshly created one). Shared by
/// the verify and setup pages so both keep the identical footprint and never
/// shift the PIN dots above them.
class VerifyingIndicator extends StatelessWidget {
  /// Overrides the default [S.pinVerifying] caption.
  final String? label;

  const VerifyingIndicator({super.key, this.label});

  @override
  Widget build(BuildContext context) => SizedBox(
    // Matches the NumberPad footprint (4 rows of ~68px) so swapping it in for
    // the spinner does not shift the PIN dots above it.
    height: 272,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 16.0,
      children: [
        const CupertinoActivityIndicator(radius: 16),
        Text(
          label ?? S.of(context).pinVerifying,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: RealUnitColors.neutral500,
          ),
        ),
      ],
    ),
  );
}
