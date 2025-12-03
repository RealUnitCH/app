import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/icons.dart';

import 'widgets/welcome_card.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: RealUnitColors.brand700,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: 24.0,
                    right: 24.0,
                    top: 40.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RealUnitIcon(size: 48),
                      SizedBox(height: 8),
                      Text(
                        'RealUnit Wallet',
                        style: const TextStyle(
                          color: RealUnitColors.realUnitBlack,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          height: 30 / 26,
                          letterSpacing: 26 * -0.02,
                        ),
                      ),
                      Text(
                        'Investiere in reale Werte und behalte die volle Kontrolle — rund um die Uhr.',
                        style: const TextStyle(
                          color: RealUnitColors.neutral500,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 22 / 16,
                          letterSpacing: 0.0,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 40.0),
                WelcomeCard(
                  title: 'Software Wallet',
                  trailing: SvgPicture.asset(
                    'assets/images/icons/software_wallet.svg',
                  ),
                  actions: [
                    WelcomeCardAction(
                      title: 'Neue Wallet erstellen',
                      onPressed: () => context.push('/wallet/create'),
                      style: WelcomeCardActionStyle.primary,
                    ),
                    WelcomeCardAction(
                      title: 'Wallet wiederherstellen',
                      onPressed: () => context.push('/wallet/restore'),
                      style: WelcomeCardActionStyle.secondary,
                    ),
                  ],
                ),
                SizedBox(
                  height: 16.0,
                ),
                WelcomeCard(
                  title: 'BitBox \nHardware Wallet',
                  trailing: SvgPicture.asset('assets/images/icons/bitbox.svg'),
                  actions: [
                    WelcomeCardAction(
                      title: 'Mit BitBox verbinden',
                      style: WelcomeCardActionStyle.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}
