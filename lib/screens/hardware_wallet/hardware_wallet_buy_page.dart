import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/setup/routing/routes/settings_routes.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';
import 'package:realunit_wallet/widgets/scrollable_actions_layout.dart';

class HardwareWalletBuyPage extends StatelessWidget {
  const HardwareWalletBuyPage({super.key});

  static final _shopUri = Uri.parse('https://shop.bitbox.swiss/');
  static final _bitbox02Uri = Uri.parse('https://bitbox.swiss/bitbox02/');
  static final _novaUri = Uri.parse('https://bitbox.swiss/bitbox02/nova/');

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.hardwareWalletBuyTitle)),
      body: SafeArea(
        child: Padding(
          padding: const .symmetric(horizontal: 20, vertical: 16),
          child: ScrollableActionsLayout(
            body: Column(
              crossAxisAlignment: .stretch,
              spacing: 16,
              children: [
                Text(s.hardwareWalletBuyBody, style: Theme.of(context).textTheme.bodyMedium),
                AppFilledButton(
                  label: s.hardwareWalletBuyShop,
                  variant: FilledButtonVariant.secondary,
                  onPressed: () => launchUrl(_shopUri, mode: LaunchMode.externalApplication),
                ),
                AppFilledButton(
                  label: s.hardwareWalletBuyBitbox02,
                  variant: FilledButtonVariant.secondary,
                  onPressed: () => launchUrl(_bitbox02Uri, mode: LaunchMode.externalApplication),
                ),
                AppFilledButton(
                  label: s.hardwareWalletBuyNova,
                  variant: FilledButtonVariant.secondary,
                  onPressed: () => launchUrl(_novaUri, mode: LaunchMode.externalApplication),
                ),
              ],
            ),
            actions: [
              AppFilledButton(
                label: s.hardwareWalletBuyConfirm,
                onPressed: () => context.pushNamed(SettingsRoutes.hardwareWalletSetup),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
