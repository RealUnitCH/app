import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';
import 'package:realunit_wallet/widgets/handlebars.dart';

class ForgotPinBottomSheet extends StatelessWidget {
  const ForgotPinBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Handlebars.horizontal(
              context,
              margin: const EdgeInsets.only(top: 5),
              width: 36,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 30.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    S.of(context).pinForgottenTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      height: 30 / 26,
                      letterSpacing: 26 * -0.02,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    S.of(context).pinForgottenDescription,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: RealUnitColors.neutral500,
                      fontSize: 14,
                      height: 18 / 14,
                      letterSpacing: 0.0,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    spacing: 12.0,
                    children: [
                      Expanded(
                        child: AppFilledButton(
                          variant: .secondary,
                          onPressed: () => context.pop(false),
                          label: S.of(context).close,
                        ),
                      ),
                      Expanded(
                        child: AppFilledButton(
                          onPressed: () => context.pop(true),
                          label: S.of(context).reset,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
