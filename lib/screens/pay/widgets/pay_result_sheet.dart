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
  });

  final IconData icon;
  final String title;
  final String description;
  final String closeLabel;
  final VoidCallback onClose;

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
                  spacing: 28,
                  children: [
                    Icon(
                      icon,
                      color: RealUnitColors.realUnitBlue,
                      size: 64,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 8,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
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
                  ],
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: AppFilledButton(
                    variant: FilledButtonVariant.secondary,
                    fullWidth: false,
                    onPressed: onClose,
                    label: closeLabel,
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
