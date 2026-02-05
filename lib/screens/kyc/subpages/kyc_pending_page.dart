import 'package:flutter/material.dart';
import 'package:realunit_wallet/screens/kyc/cubits/kyc/kyc_cubit.dart';

class KycPendingPage extends StatelessWidget {
  final KycStep pendingStep;
  const KycPendingPage({super.key, required this.pendingStep});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KYC')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              Text(
                'Ihr folgender Schritt ist gerade noch unter Prüfung: ${pendingStep.name}. Bitte haben Sie noch ein wenig Geduld und schauen Sie zu einem späteren Zeitpunkt nochmal rein.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, height: 18 / 14, letterSpacing: 0.0),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
