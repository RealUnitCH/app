import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/setup/routing/routes/settings_routes.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';
import 'package:realunit_wallet/widgets/scrollable_actions_layout.dart';

class HardwareWalletIntroPage extends StatelessWidget {
  const HardwareWalletIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.hardwareWalletIntroTitle)),
      body: SafeArea(
        child: Padding(
          padding: const .symmetric(horizontal: 20, vertical: 16),
          child: ScrollableActionsLayout(
            body: Column(
              crossAxisAlignment: .stretch,
              spacing: 16,
              children: [
                Text(s.hardwareWalletIntroBody, style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  s.hardwareWalletIntroProsTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(s.hardwareWalletIntroPros, style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  s.hardwareWalletIntroConsTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(s.hardwareWalletIntroCons, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            actions: [
              AppFilledButton(
                label: s.hardwareWalletIntroCta,
                onPressed: () => context.pushNamed(SettingsRoutes.hardwareWalletBuy),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
