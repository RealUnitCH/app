import 'package:flutter/material.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/styles/colors.dart';

class SettingsEditFailurePage extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRefresh;

  const SettingsEditFailurePage(
    this.message, {
    super.key,
    required this.title,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const .symmetric(horizontal: 20.0),
        child: SafeArea(
          child: Column(
            spacing: 8.0,
            children: [
              const Spacer(),
              Text(
                S.of(context).kycFailure,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(
                S.of(context).kycFailureDescription(message),
                textAlign: .center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: RealUnitColors.neutral500),
              ),
              Padding(
                padding: const .symmetric(vertical: 16.0),
                child: SizedBox(
                  width: .infinity,
                  child: FilledButton(
                    onPressed: onRefresh,
                    child: Text(S.of(context).refresh),
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
