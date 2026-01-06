import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/config/network_mode.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/settings/widgets/settings_section.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/styles.dart';

class SettingsNetworkPage extends StatefulWidget {
  const SettingsNetworkPage({super.key});

  @override
  State<SettingsNetworkPage> createState() => _SettingsNetworkPageState();
}

class _SettingsNetworkPageState extends State<SettingsNetworkPage> {
  NetworkMode? _pending;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          S.of(context).settings_network,
          style: kPageTitleTextStyle,
        ),
      ),
      body: BlocConsumer<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (_pending == state.networkMode) {
            setState(() => _pending = null);
          }
        },
        builder: (context, state) {
          return SettingsSections(
            settings: NetworkMode.values.map((mode) {
              final isSelected = state.networkMode == mode;
              final isLoading = _pending == mode;

              return SettingOption(
                title: mode.localizedName(context),
                trailing: isLoading
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: RealUnitColors.realUnitBlue,
                        ),
                      )
                    : isSelected
                        ? const Icon(
                            Icons.check,
                            size: 20,
                            color: RealUnitColors.realUnitBlue,
                          )
                        : null,
                onTap: () {
                  if (isSelected || _pending != null) return;
                  setState(() => _pending = mode);
                  getIt<SettingsBloc>().add(SetNetworkModeEvent(mode));
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
