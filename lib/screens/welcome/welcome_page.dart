import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/hardware_connect_bitbox/connect_bitbox_page.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/welcome/widgets/welcome_card.dart';
import 'package:realunit_wallet/setup/routing/routes/onboarding_routes.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/icons.dart';

class WelcomePage extends StatefulWidget {
  /// Pre-sets the second-step state for golden testing the create-vs-restore
  /// choice screen without driving a tap through the first-step Card.
  @visibleForTesting
  final bool initialShowSecondStep;

  const WelcomePage({super.key, this.initialShowSecondStep = false});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  late bool showSecondStep = widget.initialShowSecondStep;

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
          padding: const .symmetric(
            horizontal: 20.0,
          ),
          child: Column(
            spacing: 40.0,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                ),
                child: Column(
                  crossAxisAlignment: .start,
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
                    offset: showSecondStep ? const Offset(-1.2, 0) : .zero,
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
                        WelcomeCard(
                          title: S.of(context).bitbox,
                          description: S.of(context).hardwareWalletSubtitle,
                          trailing: SvgPicture.asset(
                            'assets/images/illustrations/bitbox.svg',
                          ),
                          onPressed: () => onBitboxPressed(context),
                        ),
                      ],
                    ),
                  ),
                  AnimatedSlide(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                    offset: showSecondStep ? .zero : const Offset(1.2, 0),
                    child: Column(
                      spacing: 16.0,
                      children: [
                        WelcomeCard(
                          title: S.of(context).createWallet,
                          description: S.of(context).softwareWalletSubtitle,
                          onPressed: () => context.pushNamed(OnboardingRoutes.createWallet),
                          trailing: SvgPicture.asset(
                            'assets/images/illustrations/create_wallet.svg',
                          ),
                        ),
                        WelcomeCard(
                          title: S.of(context).restoreWallet,
                          description: S.of(context).restoreWalletSubtitle,
                          onPressed: () => context.pushNamed(OnboardingRoutes.restoreWallet),
                          trailing: SvgPicture.asset(
                            'assets/images/illustrations/restore_wallet.svg',
                          ),
                        ),
                        if (kDebugMode)
                          WelcomeCard(
                            title: '${S.of(context).address} + ${S.of(context).signature}',
                            description: S.of(context).debugWalletDescription,
                            onPressed: () => context.pushNamed(OnboardingRoutes.debugAuth),
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

  Future<void> onBitboxPressed(BuildContext context) async {
    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (_) => ConnectBitboxPage(
        onFinish: (wallet) => context.read<HomeBloc>().add(LoadWalletEvent(wallet)),
      ),
    );
  }
}
