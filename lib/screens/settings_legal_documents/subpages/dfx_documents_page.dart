import 'package:flutter/material.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/legal/steps/legal_dfx_step.dart';

class DfxDocumentsPage extends StatelessWidget {
  const DfxDocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).dfxTitle),
      ),
      body: const SingleChildScrollView(
        child: Padding(
          padding: .symmetric(
            horizontal: 20.0,
            vertical: 12.0,
          ),
          child: LegalDfxStep(showTitle: false),
        ),
      ),
    );
  }
}
