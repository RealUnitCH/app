import 'package:flutter/material.dart';
import 'package:realunit_wallet/styles/colors.dart';

class EnableBiometricBottomSheet extends StatelessWidget {
  const EnableBiometricBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.fingerprint,
              size: 64,
              color: RealUnitColors.realUnitBlack,
            ),
            const SizedBox(height: 16),
            const Text(
              'Enable Biometric Authentication',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: RealUnitColors.realUnitBlack,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Use Face ID or fingerprint to unlock your wallet quickly and securely.',
              style: TextStyle(
                fontSize: 14,
                color: RealUnitColors.neutral500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: RealUnitColors.realUnitBlack,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Enable'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Skip for now',
                  style: TextStyle(
                    color: RealUnitColors.neutral500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
