import 'package:flutter/foundation.dart';
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
              icon: const Icon(Icons.arrow_back_rounded),
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
                    const RealUnitIcon(size: 48),
                    const SizedBox(height: 8),
                    Text(
                      S.of(context).realunitWallet,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Text(
                      S.of(context).realunitWalletSubtitle,
                      style:
                          Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(
                            color: RealUnitColors.neutral500,
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
                          title: S.of(context).softwareWallet,
                          description: S.of(context).softwareWalletSubtitle,
                          onPressed: () => setState(() => showSecondStep = true),
                          trailing: SvgPicture.asset(
                            'assets/images/illustrations/software_wallet.svg',
                          ),
                        ),
                        if (defaultTargetPlatform == TargetPlatform.android)
                          WelcomeCard(
                            title: S.of(context).bitbox,
                            description: S.of(context).hardwareWalletSubtitle,
                            trailing: SvgPicture.asset(
                              'assets/images/illustrations/bitbox.svg',
                            ),
                            onPressed: onBitboxPressed,
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
                          title: S.of(context).createWallet,
                          description: S.of(context).softwareWalletSubtitle,
                          onPressed: () => context.push('/wallet/create'),
                          trailing: SvgPicture.asset(
                            'assets/images/illustrations/create_wallet.svg',
                          ),
                        ),
                        WelcomeCard(
                          title: S.of(context).restoreWallet,
                          description: S.of(context).restoreWalletSubtitle,
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

  Future<void> onBitboxPressed() async {
    await showModalBottomSheet(
      isScrollControlled: true,
      context: navigatorKey.currentContext!,
      builder: (_) => const ConnectBitboxPage(),
    );
  }
}
