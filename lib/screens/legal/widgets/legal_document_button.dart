import 'package:flutter/material.dart';
import 'package:realunit_wallet/styles/colors.dart';

class LegalDocumentButton extends StatelessWidget {
  final IconData leadingIcon;
  final String title;
  final VoidCallback onTap;
  final IconData trailingIcon;

  const LegalDocumentButton({
    super.key,
    required this.leadingIcon,
    required this.title,
    required this.onTap,
    this.trailingIcon = Icons.chevron_right_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: .circular(12),
      child: Container(
        width: .infinity,
        padding: const .all(16),
        decoration: BoxDecoration(
          border: Border.all(color: RealUnitColors.neutral200),
          borderRadius: .circular(12),
        ),
        child: Row(
          spacing: 12.0,
          children: [
            Icon(leadingIcon, color: RealUnitColors.realUnitBlue, size: 24),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: RealUnitColors.neutral900,
                ),
              ),
            ),
            Icon(
              trailingIcon,
              color: RealUnitColors.neutral400,
            ),
          ],
        ),
      ),
    );
  }
}
