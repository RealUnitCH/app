import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/verify_seed/cubit/verify_seed_cubit.dart';
import 'package:realunit_wallet/styles/colors.dart';

class VerifySeedInputField extends StatefulWidget {
  final bool hasError;
  final List<int> wordIndices;
  final List<String> enteredWords;

  const VerifySeedInputField({
    super.key,
    required this.wordIndices,
    required this.enteredWords,
    this.hasError = false,
  }) : assert(enteredWords.length == 4);

  @override
  State<VerifySeedInputField> createState() => _VerifySeedInputFieldState();
}

class _VerifySeedInputFieldState extends State<VerifySeedInputField> {
  late final List<TextEditingController> _controllers;
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      4,
      (i) => TextEditingController(text: widget.enteredWords.elementAt(i)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const .all(16),
      decoration: BoxDecoration(
        color: RealUnitColors.basic.white,
        borderRadius: .circular(16),
        border: .all(
          color: widget.hasError ? RealUnitColors.status.red600 : RealUnitColors.okker,
          width: 1.5,
        ),
      ),
      child: Column(
        spacing: 12.0,
        children: List.generate(4, (index) {
          final wordPosition = widget.wordIndices.elementAt(index) + 1;
          return Row(
            spacing: 4.0,
            children: [
              Expanded(
                child: SizedBox(
                  child: Text(
                    S.of(context).verifySeedWordLabel('$wordPosition'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: RealUnitColors.neutral500,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _controllers.elementAt(index),
                  focusNode: _focusNodes.elementAt(index),
                  autocorrect: false,
                  enableSuggestions: false,
                  textCapitalization: .none,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: .w500),
                  textInputAction: index < widget.wordIndices.length - 1 ? .next : .done,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const .all(10.0),
                    border: OutlineInputBorder(
                      borderRadius: .circular(8.0),
                      borderSide: const BorderSide(
                        color: RealUnitColors.neutral300,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: .circular(8),
                      borderSide: const BorderSide(
                        color: RealUnitColors.neutral300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: .circular(8),
                      borderSide: const BorderSide(
                        color: RealUnitColors.realUnitBlue,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (value) => context.read<VerifySeedCubit>().updateWord(index, value),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }
}
