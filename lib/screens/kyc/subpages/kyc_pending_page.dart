import 'package:flutter/material.dart';
import 'package:realunit_wallet/screens/kyc/cubits/kyc/kyc_cubit.dart';

class KycPendingPage extends StatelessWidget {
  final KycStep pendingStep;
  const KycPendingPage({super.key, required this.pendingStep});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Pending: ${pendingStep.name}')));
  }
}
