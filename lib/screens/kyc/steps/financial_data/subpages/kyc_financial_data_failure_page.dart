import 'package:flutter/material.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/styles/colors.dart';

class KycFinancialDataFailurePage extends StatelessWidget {
  final String message;

  const KycFinancialDataFailurePage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).financialData),
      ),
      body: Center(
        child: Padding(
          padding: const .all(20.0),
          child: Text(
            message,
            textAlign: .center,
            style: TextStyle(color: RealUnitColors.status.red600),
          ),
        ),
      ),
    );
  }
}
