import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegistrationCompletedStep extends StatelessWidget {
  const RegistrationCompletedStep({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SafeArea(
        child: Column(
          spacing: 16,
          children: [
            Text('Verifikation abgeschlossen'),
            FilledButton(
              onPressed: context.pop,
              child: Text('Schließen'),
            ),
          ],
        ),
      ),
    );
  }
}
