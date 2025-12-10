import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/handlebars.dart';

class PaymentExecutedSheet extends StatelessWidget {
  const PaymentExecutedSheet({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5, bottom: 16),
                child: Handlebars.horizontal(context),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 50.0, horizontal: 30.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: RealUnitColors.realUnitBlue,
                      size: 64,
                    ),
                    SizedBox(height: 28),
                    Text(
                      S.of(context).buy_executed_title,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        height: 30 / 26,
                        letterSpacing: 26 * -0.02,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      S.of(context).buy_executed_description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: RealUnitColors.neutral500,
                        fontSize: 14,
                        height: 18 / 14,
                        letterSpacing: 0.0,
                      ),
                    ),
                    SizedBox(height: 28),
                    FilledButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(
                          RealUnitColors.neutral100,
                        ),
                        foregroundColor: WidgetStateProperty.all(
                          RealUnitColors.realUnitBlack,
                        ),
                      ),
                      onPressed: () {
                        context.pop();
                      },
                      child: Text(
                        S.of(context).close,
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
              ),
            ],
          ),
        ),
      );
}
