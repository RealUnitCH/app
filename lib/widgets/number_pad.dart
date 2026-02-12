import 'package:flutter/material.dart';

class NumberPad extends StatelessWidget {
  final VoidCallback? onDecimalPressed;
  final VoidCallback onDeletePressed;
  final void Function(int index) onNumberPressed;

  const NumberPad({
    super.key,
    required this.onNumberPressed,
    required this.onDeletePressed,
    this.onDecimalPressed,
  });

  static const _buttonStyle = TextStyle(
    fontSize: 25.0,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: GridView.count(
        childAspectRatio: 2,
        shrinkWrap: true,
        crossAxisCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(12, (index) {
          if (index == 9) {
            if (onDecimalPressed == null) return Container();
            return InkWell(
              onTap: onDecimalPressed,
              child: const Center(
                child: Text(
                  '.',
                  style: _buttonStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          } else if (index == 10) {
            index = 0;
          } else if (index == 11) {
            return InkWell(
              onTap: onDeletePressed,
              child: Semantics(
                label: 'Delete',
                button: true,
                child: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.black,
                ),
              ),
            );
          } else {
            index++;
          }

          return InkWell(
            onTap: () => onNumberPressed(index),
            child: Center(
              child: Text(
                '$index',
                style: _buttonStyle,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }),
      ),
    ),
  );
}
