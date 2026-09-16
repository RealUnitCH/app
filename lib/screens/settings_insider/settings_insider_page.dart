import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/settings/widgets/settings_section.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/styles/colors.dart';

class SettingsInsiderPage extends StatelessWidget {
  const SettingsInsiderPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(S.of(context).settingsInsiderFeatures),
    ),
    body: SingleChildScrollView(
      child: BlocBuilder<SettingsBloc, SettingsState>(
        bloc: getIt<SettingsBloc>(),
        builder: (context, state) => SettingsSections(
          settings: [
            SettingOption(
              title: S.of(context).pay,
              leading: const Icon(
                Icons.qr_code_scanner_rounded,
                size: 24,
                color: RealUnitColors.realUnitBlue,
              ),
              trailing: IgnorePointer(
                child: Switch(
                  value: state.insiderPayEnabled,
                  onChanged: (_) {},
                  activeTrackColor: RealUnitColors.realUnitBlue,
                ),
              ),
              onTap: () => getIt<SettingsBloc>().add(
                SetInsiderPayEnabledEvent(!state.insiderPayEnabled),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
