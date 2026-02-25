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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: RealUnitColors.neutral200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(leadingIcon, color: RealUnitColors.realUnitBlue, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  height: 22 / 16,
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
