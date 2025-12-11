import 'package:flutter/material.dart';
import 'package:realunit_wallet/screens/restore_wallet/widgets/mnemonic_input_field_controller.dart';
import 'package:realunit_wallet/styles/colors.dart';

class MnemonicInput extends StatelessWidget {
  final List<MnemonicInputFieldController> controllers;
  final List<FocusNode> focusNodes;
  final void Function()? onChanged;

  const MnemonicInput({
    super.key,
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RealUnitColors.okker, width: 2),
        color: RealUnitColors.basic.white,
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 12,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 3.5,
        ),
        itemBuilder: (context, index) {
          return Align(
            alignment: Alignment.center,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${index + 1}.",
                  style: TextStyle(
                    color: RealUnitColors.neutral400,
                    fontSize: 14,
                    height: 18 / 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                      style: TextStyle(
                        fontSize: 16,
                        height: 20 / 16,
                      ),
                      autocorrect: false,
                      textCapitalization: TextCapitalization.none,
                      controller: controllers[index],
                      focusNode: focusNodes[index],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (value) {
                        if (onChanged != null) onChanged!();
                        _handleSpaceJump(context, index, value);
                      }),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// handles jump between text fields when clicking on space
  void _handleSpaceJump(BuildContext context, int index, String value) {
    if (value.endsWith(" ")) {
      controllers[index].text = value.trim(); // remove the space
      controllers[index].selection = TextSelection.fromPosition(
        TextPosition(offset: controllers[index].text.length),
      );

      if (index < 11) {
        FocusScope.of(context).requestFocus(focusNodes[index + 1]);
      } else {
        focusNodes[index].unfocus();
      }
    }
  }
}
