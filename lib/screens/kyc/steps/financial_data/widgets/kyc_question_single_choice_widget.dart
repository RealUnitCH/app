import 'package:flutter/material.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/dto/kyc_financial_data_dto.dart';

class KycQuestionSingleChoiceWidget extends StatelessWidget {
  final KycFinancialQuestion question;
  final String? selectedKey;
  final ValueChanged<String> onChanged;

  const KycQuestionSingleChoiceWidget({
    super.key,
    required this.question,
    required this.selectedKey,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioGroup<String>(
      groupValue: selectedKey ?? '',
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      child: Column(
        children: (question.options ?? []).map(
          (option) {
            return ListTile(
              leading: Radio<String>(value: option.key),
              title: Text(
                option.text,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              contentPadding: .zero,
              onTap: () => onChanged(option.key),
            );
          },
        ).toList(),
      ),
    );
  }
}
