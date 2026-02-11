import 'package:flutter/material.dart';
import 'package:realunit_wallet/styles/colors.dart';

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
            const Column(
              spacing: 8.0,
              children: [
                Text(
                  'Enable Biometric Authentication',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: RealUnitColors.realUnitBlack,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Use Face ID or fingerprint to unlock your wallet quickly and securely.',
                  style: TextStyle(
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
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Enable'),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text(
                      'Skip for now',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
