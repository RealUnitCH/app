import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/settings/widgets/settings_section.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/styles.dart';

class SettingsNetworkPage extends StatelessWidget {
  const SettingsNetworkPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: Icon(
              Icons.arrow_back_rounded,
              size: 24,
            ),
          ),
          title: Text(
            S.of(context).settings_network,
            style: kPageTitleTextStyle,
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: SizedBox(
            width: double.infinity,
            child: BlocBuilder<SettingsBloc, SettingsState>(
              bloc: getIt<SettingsBloc>(),
              builder: (context, state) => SettingsSections(
                settings: NetworkMode.values
                    .map(
                      (mode) => SettingOption(
                        title: mode.localizedName(context),
                        trailing: state.networkMode == mode
                            ? Icon(
                                Icons.check,
                                size: 20,
                                color: RealUnitColors.realUnitBlue,
                              )
                            : null,
                        onTap: () => getIt<SettingsBloc>().add(SetNetworkModeEvent(mode)),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      );
}
