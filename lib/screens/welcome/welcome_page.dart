import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/router.dart';
import 'package:realunit_wallet/screens/hardware_connect_bitbox/connect_bitbox_page.dart';
import 'package:realunit_wallet/screens/welcome/widgets/welcome_card.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/icons.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool showSecondStep = false;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: RealUnitColors.brand700,
        appBar: AppBar(
          leading: showSecondStep
              ? IconButton(
                  onPressed: () => setState(() => showSecondStep = false),
                  icon: Icon(Icons.arrow_back_rounded, size: 24),
                )
              : null,
        ),
        body: SingleChildScrollView(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                spacing: 40.0,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 24.0,
                      right: 24.0,
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
                  Stack(
                    children: [
                      AnimatedSlide(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                        offset: showSecondStep ? const Offset(-1.2, 0) : Offset.zero,
                        child: Column(
                          spacing: 16.0,
                          children: [
                            WelcomeCard(
                              title: S.of(context).software_wallet,
                              description: S.of(context).software_wallet_subtitle,
                              onPressed: () => setState(() => showSecondStep = true),
                              trailing: SvgPicture.asset(
                                'assets/images/illustrations/software_wallet.svg',
                              ),
                            ),
                            WelcomeCard(
                              title: S.of(context).bitbox,
                              description: S.of(context).hardware_wallet_subtitle,
                              trailing: SvgPicture.asset(
                                'assets/images/illustrations/bitbox.svg',
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedSlide(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                        offset: showSecondStep ? Offset.zero : const Offset(1.2, 0),
                        child: Column(
                          spacing: 16.0,
                          children: [
                            WelcomeCard(
                              title: S.of(context).create_wallet,
                              description: S.of(context).software_wallet_subtitle,
                              onPressed: () => context.push('/wallet/create'),
                              trailing: SvgPicture.asset(
                                'assets/images/illustrations/create_wallet.svg',
                              ),
                            ),
                            WelcomeCard(
                              title: S.of(context).restore_wallet,
                              description: S.of(context).hardware_wallet_subtitle,
                              onPressed: () => context.push('/wallet/restore'),
                              trailing: SvgPicture.asset(
                                'assets/images/illustrations/restore_wallet.svg',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  void onBitboxPressed() {
    showModalBottomSheet(
      context: navigatorKey.currentContext!,
      backgroundColor: Colors.white,
      builder: (_) => BottomSheet(
        onClosing: () {},
        builder: (_) => ConnectBitboxPage(),
      ),
    );
  }
}
