import 'package:flutter/material.dart';
import 'package:realunit_wallet/styles/colors.dart';

class OutlinedTile extends StatelessWidget {
  final IconData leadingIcon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final IconData? trailingIcon;

  const OutlinedTile({
    super.key,
    required this.leadingIcon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailingIcon,
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
          border: .all(color: RealUnitColors.neutral200),
          borderRadius: .circular(12),
        ),
        child: Row(
          crossAxisAlignment: subtitle != null
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          spacing: 12.0,
          children: [
            Icon(leadingIcon, color: RealUnitColors.realUnitBlue, size: 24),
            Expanded(
              child: Column(
                spacing: 4.0,
                crossAxisAlignment: .start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: RealUnitColors.neutral900,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: RealUnitColors.neutral500,
                      ),
                    ),
                ],
              ),
            ),
            if (onTap != null) Icon(trailingIcon, color: RealUnitColors.neutral400),
          ],
        ),
      ),
    );
  }
}
