import 'package:flutter/material.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';
import 'package:realunit_wallet/widgets/handlebars.dart';
import 'package:realunit_wallet/widgets/scrollable_actions_layout.dart';

class PayResultSheet extends StatelessWidget {
  const PayResultSheet({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.closeLabel,
    required this.onClose,
    this.primaryLabel,
    this.onPrimary,
  }) : assert(
         (primaryLabel == null) == (onPrimary == null),
         'primaryLabel and onPrimary must both be null or both non-null',
       );

  final IconData icon;
  final String title;
  final String description;
  final String closeLabel;
  final VoidCallback onClose;
  final String? primaryLabel;
  final VoidCallback? onPrimary;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Handlebars.horizontal(context, margin: const EdgeInsets.only(top: 5), width: 36),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.9,
            ),
            child: ScrollableActionsLayout(
              shrinkWrap: true,
              body: Padding(
                padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      color: RealUnitColors.realUnitBlue,
                      size: 64,
                    ),
                    const SizedBox(height: 28),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: RealUnitColors.neutral500,
                        letterSpacing: 0.0,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                if (onPrimary == null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: AppFilledButton(
                      variant: FilledButtonVariant.secondary,
                      fullWidth: false,
                      onPressed: onClose,
                      label: closeLabel,
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 28),
                    // At text scale 3 a half-width button grows taller than the sheet.
                    // The matrix test requires that button to stay fully inside it.
                    child: MediaQuery.textScalerOf(context).scale(1) >= 3
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 12,
                            children: [
                              AppFilledButton(
                                variant: FilledButtonVariant.secondary,
                                onPressed: onClose,
                                label: closeLabel,
                              ),
                              AppFilledButton(
                                onPressed: onPrimary,
                                label: primaryLabel!,
                              ),
                            ],
                          )
                        : Row(
                            spacing: 12,
                            children: [
                              Expanded(
                                child: AppFilledButton(
                                  variant: FilledButtonVariant.secondary,
                                  onPressed: onClose,
                                  label: closeLabel,
                                ),
                              ),
                              Expanded(
                                child: AppFilledButton(
                                  onPressed: onPrimary,
                                  label: primaryLabel!,
                                ),
                              ),
                            ],
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
