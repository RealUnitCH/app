import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';

class KycLevelReachedPage extends StatelessWidget {
  const KycLevelReachedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).completed)),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SafeArea(
          child: Column(
            spacing: 24,
            children: [
              const Spacer(),
              const Text(
                'Verifikation abgeschlossen',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                  letterSpacing: 26 * -0.02,
                  height: 30 / 26,
                ),
              ),

              Text(
                'Danke für die Verifizierung. Sie haben nun genug Rechte um die Aktionen durchzuführen.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, height: 18 / 14, letterSpacing: 0.0),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(onPressed: context.pop, child: Text(S.of(context).close)),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
