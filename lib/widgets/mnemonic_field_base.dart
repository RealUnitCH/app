part of 'mnemonic_field.dart';

class _MnemonicFieldBase extends StatelessWidget {
  final Widget Function(BuildContext context, int index) cellBuilder;
  final void Function(int index)? onCellTap;
  final Color borderColor;
  final double borderWidth;

  const _MnemonicFieldBase({
    required this.cellBuilder,
    this.onCellTap,
    required this.borderColor,
    required this.borderWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      padding: const EdgeInsets.symmetric(
        horizontal: 12.0,
        vertical: 8.0,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: borderWidth),
        color: RealUnitColors.basic.white,
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: 12,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 3.6,
        ),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: onCellTap != null ? () => onCellTap!(index) : null,
            child: Align(
              alignment: Alignment.center,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      '${index + 1}.',
                      style: const TextStyle(
                        color: RealUnitColors.neutral400,
                        fontSize: 14,
                        height: 1.0,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 14,
                    child: cellBuilder(context, index),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
