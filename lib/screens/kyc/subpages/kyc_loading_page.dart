import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:realunit_wallet/generated/i18n.dart';

class KycLoadingPage extends StatelessWidget {
  const KycLoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).kyc),
      ),
      body: const Center(child: CupertinoActivityIndicator()),
    );
  }
}
