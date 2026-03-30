import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class KycLoadingPage extends StatelessWidget {
  const KycLoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Center(child: CupertinoActivityIndicator()),
    );
  }
}
