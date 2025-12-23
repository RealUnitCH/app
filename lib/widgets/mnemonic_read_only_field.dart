part of 'mnemonic_field.dart';

class MnemonicReadOnlyField extends StatelessWidget {
  final List<String> seedWords;

  const MnemonicReadOnlyField({
    super.key,
    required this.seedWords,
  }) : assert(seedWords.length == 12);

  @override
  Widget build(BuildContext context) {
    return _MnemonicFieldBase(
      borderColor: RealUnitColors.okker,
      borderWidth: 1.5,
      cellBuilder: (_, index) => Text(
        seedWords.elementAt(index),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 16,
          height: 1.0,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.3,
          color: RealUnitColors.neutral900,
        ),
      ),
    );
  }
}
