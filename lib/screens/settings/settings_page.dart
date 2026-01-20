import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/settings/widgets/settings_confirm_logout_wallet_sheet.dart';
import 'package:realunit_wallet/screens/settings/widgets/settings_section.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/icons.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const _forwardIcon = Icon(
    Icons.arrow_forward_ios,
    size: 20,
    color: RealUnitColors.realUnitBlack,
  );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(
            S.of(context).settings,
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              BlocBuilder<SettingsBloc, SettingsState>(
                bloc: getIt<SettingsBloc>(),
                builder: (context, state) => SettingsSections(
                  settings: [
                    SettingOption(
                      title: S.of(context).settingsLanguages,
                      leading: const LanguagesIcon(size: 24),
                      trailing: _forwardIcon,
                      selectedOption: state.language.name,
                      onTap: () => context.push('/settings/languages'),
                    ),
                    SettingOption(
                      title: S.of(context).settingsCurrency,
                      leading: const CurrencyIcon(size: 24),
                      trailing: _forwardIcon,
                      selectedOption: state.currency.code,
                      onTap: () => context.push('/settings/currencies'),
                    ),
                    SettingOption(
                      title: S.of(context).settingsNetwork,
                      leading: const NodesIcon(size: 24),
                      trailing: _forwardIcon,
                      selectedOption: state.networkMode.localizedName(context),
                      onTap: () => context.push('/settings/network'),
                    ),
                    SettingOption(
                        title: S.of(context).settingsTaxReport,
                        leading: const DocumentReportIcon(size: 24),
                        trailing: _forwardIcon,
                        onTap: () => context.push('/settings/taxReport')),
                    SettingOption(
                      title: S.of(context).kycStatus,
                      leading: const IdentificationIcon(size: 24),
                      trailing: _forwardIcon,
                      onTap: null,
                    ),
                    SettingOption(
                      title: S.of(context).userData,
                      leading: const UserCircleIcon(size: 24),
                      trailing: _forwardIcon,
                      onTap: null,
                    ),
                    if (context.read<HomeBloc>().state.openWallet?.walletType ==
                        WalletType.software)
                      SettingOption(
                        title: S.of(context).settingsWalletBackup,
                        leading: const KeySolidIcon(size: 24),
                        trailing: _forwardIcon,
                        onTap: () => context.push('/settings/seed'),
                      ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Divider(color: RealUnitColors.neutral200),
              ),
              SettingsSections(
                settings: [
                  SettingOption(
                    title: S.of(context).settingsDeleteWallet,
                    leading: const XCircleIcon(size: 24),
                    onTap: () async {
                      bool? isLogout = await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => const SettingsConfirmLogoutWalletSheet(),
                      );
                      if (isLogout ?? false) {
                        await Future.delayed(const Duration(milliseconds: 300));
                        if (context.mounted) {
                          context.read<HomeBloc>().add(const DeleteCurrentWalletEvent());
                        }
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}
