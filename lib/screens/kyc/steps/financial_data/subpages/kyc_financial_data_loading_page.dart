import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:realunit_wallet/generated/i18n.dart';

class KycFinancialDataLoadingPage extends StatelessWidget {
  const KycFinancialDataLoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).financialData),
      ),
      body: const Center(
        child: CupertinoActivityIndicator(),
      ),
    );
  }
}
