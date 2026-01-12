part of 'mnemonic_field.dart';

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
    if (value.endsWith(' ')) {
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
