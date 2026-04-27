import 'package:flutter/material.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/styles/colors.dart';

class SettingsEditRequiresTfaPage extends StatelessWidget {
  final String title;
  final VoidCallback onVerify;

  const SettingsEditRequiresTfaPage({
    super.key,
    required this.title,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: SafeArea(
          child: Column(
            spacing: 8.0,
            children: [
              const Spacer(),
              Text(
                S.of(context).twoFaRequired,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(
                S.of(context).twoFaRequiredDescription,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: RealUnitColors.neutral500),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onVerify,
                    child: Text(S.of(context).twoFaVerify),
                  ),
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
