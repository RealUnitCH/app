import 'package:flutter/material.dart';
import 'package:realunit_wallet/styles/colors.dart';

class PaymentActionRequired extends StatelessWidget {
  final String title;
  final String description;
  final Widget? action;

  const PaymentActionRequired({
    super.key,
    required this.title,
    required this.description,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 20,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          spacing: 12,
          children: [
            const Icon(
              Icons.info,
              size: 16,
              color: RealUnitColors.realUnitBlue,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 18 / 14,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 18 / 14,
                      letterSpacing: 0.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (action != null) action!,
      ],
    );
  }
}
