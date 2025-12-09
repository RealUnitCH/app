import 'package:flutter/material.dart';
import 'package:realunit_wallet/styles/colors.dart';

class PaymentNotPossibleInfo extends StatelessWidget {
  const PaymentNotPossibleInfo({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        spacing: 16.0,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Color(0xFFFCE8E8),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: Color(0xFFE02523),
                width: 1.0,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 6,
                children: [
                  Text(
                    'Kauf momentan nicht möglich.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 20 / 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Es scheint ein Berechtigungsproblem vorzuliegen. Kontaktieren Sie bitte den Support für weitere Informationen.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 18 / 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(
                RealUnitColors.neutral100,
              ),
              foregroundColor: WidgetStateProperty.all(
                RealUnitColors.realUnitBlack,
              ),
            ),
            onPressed: null,
            child: Text(
              'Support kontaktieren',
              style: TextStyle(
                color: RealUnitColors.realUnitBlack,
                fontSize: 16,
                height: 20 / 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
