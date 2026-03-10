import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class KycFinancialDataLoadingPage extends StatelessWidget {
  const KycFinancialDataLoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Center(
        child: CupertinoActivityIndicator(),
      ),
    );
  }
}
