import 'package:flutter/material.dart';
import 'package:realunit_wallet/styles/colors.dart';

enum WelcomeCardActionStyle {
  primary,
  secondary,
}

class WelcomeCardAction {
  final String title;
  final VoidCallback? onPressed;
  final WelcomeCardActionStyle style;

  WelcomeCardAction({
    required this.title,
    this.onPressed,
    this.style = WelcomeCardActionStyle.primary,
  });
}

class WelcomeCard extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final List<WelcomeCardAction> actions;

  const WelcomeCard({
    super.key,
    required this.title,
    this.trailing,
    this.actions = const <WelcomeCardAction>[],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          spacing: 24,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: RealUnitColors.realUnitBlack,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 24 / 20,
                    letterSpacing: 20 * -0.01,
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            if (actions.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: actions
                    .map((action) => FilledButton(
                          onPressed: action.onPressed,
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                              action.style == WelcomeCardActionStyle.secondary
                                  ? RealUnitColors.neutral100
                                  : RealUnitColors.brand600,
                            ),
                            foregroundColor: WidgetStateProperty.all(
                              action.style == WelcomeCardActionStyle.secondary
                                  ? RealUnitColors.realUnitBlack
                                  : Colors.white,
                            ),
                            padding: WidgetStateProperty.all(
                              const EdgeInsets.all(8),
                            ),
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          child: Text(action.title),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}
