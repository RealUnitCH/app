import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/mnemonic_input_field_controller.dart';

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
  })  : assert(controllers.length == 12),
        assert(focusNodes.length == 12);

  @override
  Widget build(BuildContext context) {
    return _MnemonicFieldBase(
      borderColor: borderColor,
      borderWidth: 2,
      onCellTap: (index) => FocusScope.of(context).requestFocus(focusNodes.elementAt(index)),
      cellBuilder: (context, index) => Focus(
        onKeyEvent: (_, event) => _handleBackspace(context, index, event),
        child: TextField(
          style: const TextStyle(
            fontSize: 16,
            height: 1.0,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.3,
          ),
          autocorrect: false,
          keyboardType: TextInputType.text,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.none,
          controller: controllers.elementAt(index),
          focusNode: focusNodes.elementAt(index),
          textInputAction:
              index == controllers.length - 1 ? TextInputAction.done : TextInputAction.next,
          decoration: const InputDecoration(
            isDense: true,
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (value) {
            _handleSpaceJump(context, index, value);
            if (index == 0) _handleMnemonicPaste(context, value);
            onChanged?.call();
          },
        ),
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

extension SeedStringExtension on String {
  List<String> get seedWords => trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
}
