import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/settings/widgets/settings_section.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/icons.dart';

class SettingsDebugPage extends StatelessWidget {
  const SettingsDebugPage({super.key});

  static const _forwardIcon = Icon(
    Icons.arrow_forward_ios,
    size: 20,
    color: RealUnitColors.realUnitBlack,
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        'Debug',
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
                  title: S.of(context).settingsNetwork,
                  leading: const NodesIcon(size: 24),
                  trailing: _forwardIcon,
                  selectedOption: state.networkMode.localizedName(context),
                  onTap: () => context.push('/settings/debug/network'),
                ),
                SettingOption(
                  title: 'Wallet-Adresse',
                  leading: const RealUnitIcon(size: 24),
                  trailing: _forwardIcon,
                  onTap: () => context.push('/settings/debug/address'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
