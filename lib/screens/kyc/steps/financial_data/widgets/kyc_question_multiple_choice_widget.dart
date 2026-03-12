import 'package:flutter/material.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/dto/kyc_financial_data_dto.dart';

class KycQuestionMultipleChoiceWidget extends StatelessWidget {
  final KycFinancialQuestion question;
  final Set<String> selectedKeys;
  final ValueChanged<Set<String>> onChanged;

  const KycQuestionMultipleChoiceWidget({
    super.key,
    required this.question,
    required this.selectedKeys,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: (question.options ?? []).map((option) {
        final isSelected = selectedKeys.contains(option.key);
        return CheckboxListTile(
          value: isSelected,
          onChanged: (v) {
            final updated = Set<String>.from(selectedKeys);
            if (v == true) {
              updated.add(option.key);
            } else {
              updated.remove(option.key);
            }
            onChanged(updated);
          },
          title: Text(
            option.text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          controlAffinity: .leading,
          contentPadding: .zero,
        );
      }).toList(),
    );
  }
}
