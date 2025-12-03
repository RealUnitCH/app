import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
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
                        S.of(context).realunit_wallet,
                        style: const TextStyle(
                          color: RealUnitColors.realUnitBlack,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          height: 30 / 26,
                          letterSpacing: 26 * -0.02,
                        ),
                      ),
                      Text(
                        S.of(context).realunit_wallet_subtitle,
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
                  title: S.of(context).software_wallet,
                  trailing: SvgPicture.asset(
                    'assets/images/icons/software_wallet.svg',
                  ),
                  actions: [
                    WelcomeCardAction(
                      title: S.of(context).create_wallet,
                      onPressed: () => context.push('/wallet/create'),
                      style: WelcomeCardActionStyle.primary,
                    ),
                    WelcomeCardAction(
                      title: S.of(context).restore_wallet,
                      onPressed: () => context.push('/wallet/restore'),
                      style: WelcomeCardActionStyle.secondary,
                    ),
                  ],
                ),
                SizedBox(
                  height: 16.0,
                ),
                WelcomeCard(
                  title: '${S.of(context).bitbox}\n${S.of(context).hardware_wallet}',
                  trailing: SvgPicture.asset('assets/images/icons/bitbox.svg'),
                  actions: [
                    WelcomeCardAction(
                      title: S.of(context).connect_with(S.of(context).bitbox),
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
