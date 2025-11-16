import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/settings/widgets/settings_section.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/styles.dart';
import 'package:realunit_wallet/styles/icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const _forwardIcon = Icon(
    Icons.arrow_forward_ios,
    size: 20,
    color: DEuroColors.anthracite,
  );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: CupertinoNavigationBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: DEuroColors.anthracite,
              size: 24,
            ),
          ),
          middle: Text(
            S.of(context).settings,
            style: kPageTitleTextStyle,
          ),
          border: null,
        ),
        body: SingleChildScrollView(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                BlocBuilder<SettingsBloc, SettingsState>(
                  bloc: getIt<SettingsBloc>(),
                  builder: (context, state) => SettingsSections(
                    title: S.of(context).settings_general,
                    settings: [
                      SettingOption(
                        title: S.of(context).settings_nodes,
                        leading: NodesIcon(size: 24),
                        trailing: _forwardIcon,
                        onTap: () => context.push('/settings/nodes'),
                      ),
                      SettingOption(
                        title: S.of(context).settings_languages,
                        leading: LanguagesIcon(
                          size: 24,
                        ),
                        trailing: _forwardIcon,
                        selectedOption: state.language.name,
                        onTap: () => context.push('/settings/languages'),
                      ),
                    ],
                  ),
                ),
                SettingsSections(
                  title: S.of(context).settings_dangerzone,
                  settings: [
                    SettingOption(
                      title: S.of(context).show_seed,
                      leading: RecoveryKeyIcon(size: 24),
                      trailing: _forwardIcon,
                      onTap: () => context.push('/settings/seed'),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(top: 36, bottom: 36),
                  child: TextButton(
                    onPressed: () => context
                        .read<HomeBloc>()
                        .add(DeleteCurrentWalletEvent()),
                    style: TextButton.styleFrom(
                      fixedSize: Size(double.infinity, 46),
                      backgroundColor: DEuroColors.neutralGrey93,
                      padding: EdgeInsets.only(left: 24, right: 24),
                    ),
                    child: Text(
                      S.of(context).sign_out,
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
