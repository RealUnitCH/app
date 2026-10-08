import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/setup/routing/routes/app_routes.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';
import 'package:realunit_wallet/widgets/scrollable_actions_layout.dart';

class HardwareWalletPairedPage extends StatelessWidget {
  const HardwareWalletPairedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.hardwareWalletPairedTitle)),
      body: SafeArea(
        child: Padding(
          padding: const .symmetric(horizontal: 20, vertical: 16),
          child: ScrollableActionsLayout(
            body: Text(
              s.hardwareWalletPairedBody,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            actions: [
              AppFilledButton(
                label: s.hardwareWalletRegisterAddress,
                onPressed: () => registerBitboxAddress(context),
              ),
              AppFilledButton(
                label: s.next,
                variant: FilledButtonVariant.secondary,
                onPressed: () => context.goNamed(AppRoutes.dashboard),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> registerBitboxAddress(BuildContext context) async {
  final wallets = await getIt<WalletService>().listWallets();
  AWallet? bitbox;
  for (final wallet in wallets) {
    if (wallet.walletType == WalletType.bitbox) {
      bitbox = wallet;
      break;
    }
  }
  if (bitbox == null || !context.mounted) {
    return;
  }
  final homeBloc = context.read<HomeBloc>();
  final pending = homeBloc.stream.firstWhere((state) => state.openWallet?.id == bitbox!.id);
  homeBloc.add(SwitchWalletEvent(bitbox.id));
  await pending;
  if (!context.mounted) {
    return;
  }
  context.pushNamed(AppRoutes.kyc);
}
