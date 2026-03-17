import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SettingsEditLoadingPage extends StatelessWidget {
  final String title;

  const SettingsEditLoadingPage({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(child: CupertinoActivityIndicator()),
    );
  }
}
