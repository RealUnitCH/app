import 'package:flutter/material.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/mnemonic_input_field_controller.dart';

class MnemonicInputField extends StatelessWidget {
  final List<MnemonicInputFieldController> controllers;
  final List<FocusNode> focusNodes;
  final void Function()? onChanged;
  final Color borderColor;

  const MnemonicInputField({
    super.key,
    required this.controllers,
    required this.focusNodes,
    this.borderColor = RealUnitColors.okker,
    this.onChanged,
  })  : assert(controllers.length == 12, 'Exactly 12 controllers are required'),
        assert(focusNodes.length == 12, 'Exactly 12 focusNodes are required');

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
        border: Border.all(color: borderColor, width: 2),
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
          return GestureDetector(
            onTap: () => FocusScope.of(context).requestFocus(focusNodes[index]),
            child: Align(
              alignment: Alignment.center,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      "${index + 1}.",
                      style: TextStyle(
                        color: RealUnitColors.neutral400,
                        fontSize: 14,
                        height: 18 / 14,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 11,
                    child: TextField(
                      style: TextStyle(
                        fontSize: 16,
                        height: 20 / 16,
                      ),
                      autocorrect: false,
                      textCapitalization: TextCapitalization.none,
                      controller: controllers[index],
                      focusNode: focusNodes[index],
                      textInputAction: index == controllers.length - 1
                          ? TextInputAction.done
                          : TextInputAction.next,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (value) {
                        if (onChanged != null) onChanged!();
                        _handleSpaceJump(context, index, value);
                      },
                    ),
                  ),
                ],
              ),
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

      if (index < controllers.length - 1) {
        FocusScope.of(context).requestFocus(focusNodes[index + 1]);
      } else {
        FocusManager.instance.primaryFocus?.unfocus();
      }
    }
  }
}
