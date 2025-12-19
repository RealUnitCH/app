import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        horizontal: 12.0,
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
          childAspectRatio: 3.6,
        ),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => FocusScope.of(context).requestFocus(focusNodes.elementAt(index)),
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
                    flex: 13,
                    child: Focus(
                      onKeyEvent: (_, event) => _handleBackspace(context, index, event),
                      child: TextField(
                        style: TextStyle(
                          fontSize: 16,
                          height: 20 / 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.3,
                        ),
                        autocorrect: false,
                        textCapitalization: TextCapitalization.none,
                        controller: controllers.elementAt(index),
                        focusNode: focusNodes.elementAt(index),
                        textInputAction: index == controllers.length - 1
                            ? TextInputAction.done
                            : TextInputAction.next,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) {
                          _handleSpaceJump(context, index, value);
                          if (index == 0) _handleMnemonicPaste(context, value);
                          if (onChanged != null) onChanged!();
                        },
                      ),
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

  void _handleMnemonicPaste(BuildContext context, String value) {
    final words = value.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length < 2) return;

    for (int i = 0; i < controllers.length; i++) {
      controllers.elementAt(i).text = i < words.length ? words.elementAt(i) : '';
    }

    final nextIndex = words.length.clamp(0, controllers.length - 1);
    if (nextIndex < controllers.length) {
      FocusScope.of(context).requestFocus(focusNodes.elementAt(nextIndex));
    } else {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  void _handleSpaceJump(BuildContext context, int index, String value) {
    if (value.endsWith(" ")) {
      final controller = controllers.elementAt(index);
      controller.text = value.trim(); // remove the space
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length),
      );

      if (index < controllers.length - 1) {
        FocusScope.of(context).requestFocus(focusNodes.elementAt(index + 1));
      } else {
        FocusManager.instance.primaryFocus?.unfocus();
      }
    }
  }

  KeyEventResult _handleBackspace(BuildContext context, int index, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      if (controllers.elementAt(index).text.isEmpty && index > 0) {
        FocusScope.of(context).requestFocus(focusNodes.elementAt(index - 1));
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }
}
