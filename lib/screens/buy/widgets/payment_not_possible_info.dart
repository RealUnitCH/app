import 'package:flutter/material.dart';
import 'package:realunit_wallet/generated/i18n.dart';
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
              color: RealUnitColors.status.red100,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: RealUnitColors.status.red600,
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
                    S.of(context).buy_payment_not_possible,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 20 / 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    S.of(context).buy_payment_not_possible_description,
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
              S.of(context).contact_support,
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
