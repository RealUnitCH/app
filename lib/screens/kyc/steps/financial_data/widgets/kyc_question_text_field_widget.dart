import 'package:flutter/material.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/dto/kyc_financial_data_dto.dart';

class KycQuestionTextFieldWidget extends StatefulWidget {
  final KycFinancialQuestion question;
  final String value;
  final ValueChanged<String> onChanged;

  const KycQuestionTextFieldWidget({
    super.key,
    required this.question,
    required this.value,
    required this.onChanged,
  });

  @override
  State<KycQuestionTextFieldWidget> createState() => _KycQuestionTextFieldWidgetState();
}

class _KycQuestionTextFieldWidgetState extends State<KycQuestionTextFieldWidget> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: widget.question.title,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      maxLines: 3,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
