import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/io/installer_package_adapter.dart';
import 'package:realunit_wallet/packages/io/installer_package_port.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/utils/store_update_target.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/pin/verify_pin_page.dart';
import 'package:realunit_wallet/screens/update_required/bloc/client_policy_cubit.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/setup/routing/routes/app_routes.dart';
import 'package:realunit_wallet/setup/routing/routes/pin_routes.dart';
import 'package:realunit_wallet/setup/routing/routes/settings_routes.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';
import 'package:realunit_wallet/widgets/scrollable_actions_layout.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateRequiredPage extends StatefulWidget {
  const UpdateRequiredPage({
    super.key,
    this.installerPackage = const InstallerPackageAdapter(),
  });

  final InstallerPackagePort installerPackage;

  @override
  State<UpdateRequiredPage> createState() => _UpdateRequiredPageState();
}

class _UpdateRequiredPageState extends State<UpdateRequiredPage> {
  String? _installer;

  @override
  void initState() {
    super.initState();
    widget.installerPackage.readInstallerPackage().then((value) {
      if (!mounted) return;
      setState(() => _installer = value);
    });
  }

  void _open(String url) {
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).updateRequiredTitle),
          automaticallyImplyLeading: false,
        ),
        body: BlocBuilder<ClientPolicyCubit, ClientPolicyState>(
          builder: (context, state) {
            final policy = state is ClientPolicyLoaded ? state.policy : null;
            final home = context.watch<HomeBloc>().state;
            final hasWallet = home.hasWallet;
            final bitboxAddressRecoveryNeeded = home.bitboxAddressRecoveryNeeded;
            final walletType = getIt<AppStore>().isWalletLoaded
                ? getIt<AppStore>().wallet.walletType
                : null;
            final target = policy == null
                ? const StoreUpdateTarget()
                : pickStoreUpdate(
                    isIOS: Platform.isIOS,
                    installerPackage: _installer,
                    policy: policy,
                  );

            return ScrollableActionsLayout(
              padding: const .all(20),
              body: Column(
                spacing: 16.0,
                crossAxisAlignment: .stretch,
                children: [
                  Text(S.of(context).updateRequiredBody),
                  if (target.primaryUrl == null)
                    Text(S.of(context).updateRequiredUnavailable),
                ],
              ),
              actions: [
                if (target.primaryUrl != null)
                  AppFilledButton(
                    label: S.of(context).updateRequiredCta,
                    onPressed: () => _open(target.primaryUrl!),
                  ),
                if (target.githubSecondaryUrl != null &&
                    target.githubSecondaryUrl != target.primaryUrl)
                  AppFilledButton(
                    variant: .secondary,
                    label: S.of(context).updateRequiredGithubSecondary,
                    onPressed: () => _open(target.githubSecondaryUrl!),
                  ),
                if (hasWallet && walletType == WalletType.software)
                  AppFilledButton(
                    variant: .secondary,
                    label: S.of(context).updateRequiredBackup,
                    onPressed: () => context.pushNamed(
                      PinRoutes.gate,
                      extra: VerifyPinParams(
                        onAuthenticated: () =>
                            context.pushReplacementNamed(SettingsRoutes.seed),
                        description: S.of(context).pinVerifySeedDescription,
                      ),
                    ),
                  ),
                if (hasWallet && !bitboxAddressRecoveryNeeded)
                  AppFilledButton(
                    variant: .secondary,
                    label: S.of(context).updateRequiredReceive,
                    onPressed: () => context.pushNamed(AppRoutes.receive),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
