import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/config/network_mode.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/settings/widgets/settings_section.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/styles/colors.dart';

class SettingsNetworkPage extends StatelessWidget {
  SettingsNetworkPage({super.key});

  final _loadingModel = _LoadingNetworkModeModel();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          S.of(context).settingsNetwork,
        ),
      ),
      body: BlocConsumer<SettingsBloc, SettingsState>(
        listener: (context, state) => _loadingModel.loadingFinished(),
        builder: (context, state) {
          return ValueListenableBuilder(
            valueListenable: _loadingModel,
            builder: (context, value, child) {
              return SettingsSections(
                settings: NetworkMode.values.map((mode) {
                  final isSelected = state.networkMode == mode;
                  final isLoading = value == mode;

                  return SettingOption(
                    title: mode.localizedName(context),
                    trailing: isLoading
                        ? const SizedBox(
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
                      if (isSelected || value != null) return;
                      _loadingModel.setLoading(mode);
                      getIt<SettingsBloc>().add(SetNetworkModeEvent(mode));
                    },
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}

class _LoadingNetworkModeModel extends ValueNotifier<NetworkMode?> {
  _LoadingNetworkModeModel() : super(null);

  void setLoading(NetworkMode mode) => value = mode;

  void loadingFinished() => value = null;
}
