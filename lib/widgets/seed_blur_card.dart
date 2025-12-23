import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/mnemonic_field.dart';

class SeedBlurCard extends StatelessWidget {
  final String seed;
  final bool blur;
  final VoidCallback onTap;

  const SeedBlurCard({
    super.key,
    required this.seed,
    required this.blur,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            MnemonicReadOnlyField(
              seedWords: seed.seedWords,
            ),
            if (blur)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(1.5),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        color: RealUnitColors.basic.white.withValues(alpha: 0.15),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.visibility_outlined,
                              size: 16,
                              color: RealUnitColors.realUnitBlack,
                            ),
                            Text(
                              S.of(context).tap_here_to_view,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 18 / 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}
