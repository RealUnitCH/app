import 'package:realunit_wallet/styles/styles.dart';
import 'package:flutter/material.dart';

class TextDivider extends StatelessWidget {
  final String text;

  const TextDivider({super.key, required this.text});

  @override
  Widget build(BuildContext context) => Row(children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.only(left: 10, right: 10),
          child: Text(text, style: kPrimaryButtonTextStyle),
        ),
        const Expanded(child: Divider()),
      ]);
}
