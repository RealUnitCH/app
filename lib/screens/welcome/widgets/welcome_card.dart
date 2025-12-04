import 'package:flutter/material.dart';
import 'package:realunit_wallet/styles/colors.dart';

class WelcomeCard extends StatelessWidget {
  final String title;
  final String? description;
  final Widget? trailing;
  final VoidCallback? onPressed;

  const WelcomeCard({
    super.key,
    required this.title,
    this.description,
    this.trailing,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            spacing: 24,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                spacing: 20,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      spacing: 8.0,
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                        if (description != null)
                          Text(
                            description!,
                            style: const TextStyle(
                              color: RealUnitColors.neutral500,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 18 / 14,
                              letterSpacing: 0.0,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
