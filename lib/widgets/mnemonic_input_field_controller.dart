part of 'mnemonic_field.dart';

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
