// ignore: implementation_imports
import 'package:bip39/src/wordlists/english.dart' as wordlist;
import 'package:flutter/material.dart';
import 'package:realunit_wallet/styles/colors.dart';

class MnemonicInputFieldController extends TextEditingController {
  final nonMatchStyle = TextStyle(color: RealUnitColors.status.red600);

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final isMatching = wordlist.WORDLIST.contains(text) ? style : style?.merge(nonMatchStyle);

    return TextSpan(
      text: text,
      style: isMatching,
    );
  }
}
