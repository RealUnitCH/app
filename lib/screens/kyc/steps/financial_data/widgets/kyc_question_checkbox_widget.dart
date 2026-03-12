import 'package:flutter/material.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/dto/kyc_financial_data_dto.dart';

class KycQuestionCheckboxWidget extends StatelessWidget {
  final KycFinancialQuestion question;
  final bool value;
  final ValueChanged<bool> onChanged;

  const KycQuestionCheckboxWidget({
    super.key,
    required this.question,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: (v) => onChanged(v ?? false),
      title: Text(
        question.options?.firstOrNull?.text ?? question.title,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      controlAffinity: .leading,
      contentPadding: .zero,
    );
  }
}
