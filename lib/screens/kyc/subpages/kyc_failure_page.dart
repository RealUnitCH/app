import 'package:flutter/material.dart';

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
            children: [
              Spacer(),
              Text(
                'Es ist beim Laden ein Fehler aufgekommen. Bitte versuchen Sie es zu einem späteren Zeitpunkt',
                textAlign: TextAlign.center,
                style: TextStyle(
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
