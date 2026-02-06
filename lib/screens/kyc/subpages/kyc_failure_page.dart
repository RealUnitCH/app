import 'package:flutter/material.dart';
import 'package:realunit_wallet/styles/colors.dart';

class KycFailurePage extends StatelessWidget {
  final String message;

  const KycFailurePage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KYC')),
      body: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.0),
        child: SafeArea(
          child: Column(
            spacing: 8.0,
            children: [
              Spacer(),
              Text(
                'Fehler beim Laden',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  height: 30 / 26,
                  letterSpacing: -0.52,
                ),
              ),
              Text(
                'Es ist ein Fehler beim Laden aufgekommen. Bitte versuchen Sie es zu einem späteren Zeitpunkt. Falls der Fehler weiterhin besteht, kontaktieren Sie unseren Support.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: RealUnitColors.neutral500,
                  fontSize: 14,
                  height: 18 / 14,
                  letterSpacing: 0.0,
                ),
              ),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
