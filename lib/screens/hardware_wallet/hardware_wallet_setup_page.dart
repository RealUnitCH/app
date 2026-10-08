import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/screens/hardware_connect_bitbox/connect_bitbox_page.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/setup/routing/routes/settings_routes.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';
import 'package:realunit_wallet/widgets/scrollable_actions_layout.dart';

class HardwareWalletSetupPage extends StatelessWidget {
  const HardwareWalletSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.hardwareWalletSetupTitle)),
      body: SafeArea(
        child: Padding(
          padding: const .symmetric(horizontal: 20, vertical: 16),
          child: ScrollableActionsLayout(
            body: Column(
              crossAxisAlignment: .stretch,
              spacing: 16,
              children: [
                Text(s.hardwareWalletSetupBody, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            actions: [
              AppFilledButton(
                label: s.hardwareWalletSetupConfirm,
                onPressed: () => _openConnect(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openConnect(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ConnectBitboxPage(
          acquireWallet: () => getIt<WalletService>().addBitboxWallet('BitBox'),
          onFinish: (_) {
            if (context.mounted) {
              context.goNamed(SettingsRoutes.hardwareWalletPaired);
            }
          },
        ),
      ),
    );
  }
}
