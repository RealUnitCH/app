import 'package:flutter/material.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';
import 'package:realunit_wallet/widgets/buttons/app_text_button.dart';

class EnableBiometricBottomSheet extends StatelessWidget {
  const EnableBiometricBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          spacing: 32.0,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.fingerprint,
              size: 64,
              color: RealUnitColors.realUnitBlue,
            ),
            Column(
              spacing: 8.0,
              children: [
                Text(
                  S.of(context).biometricAuthenticationActivate,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: RealUnitColors.realUnitBlack,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  S.of(context).biometricAuthenticationActivateDescription,
                  style: const TextStyle(
                    fontSize: 14,
                    color: RealUnitColors.neutral500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            Column(
              spacing: 8.0,
              children: [
                AppFilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  label: S.of(context).enable,
                ),
                AppTextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  label: S.of(context).skip,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
