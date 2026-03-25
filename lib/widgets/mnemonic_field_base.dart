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
    const columns = 2;
    const rows = 6;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: borderWidth),
        color: RealUnitColors.basic.white,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(rows, (rowIndex) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: List.generate(columns, (colIndex) {
                final index = rowIndex + colIndex * rows;
                return Expanded(
                  child: GestureDetector(
                    onTap: onCellTap != null ? () => onCellTap!(index) : null,
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
              }),
            ),
          );
        }),
      ),
    );
  }
}
