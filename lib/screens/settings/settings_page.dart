import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/settings/widgets/settings_section.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/icons.dart';
import 'package:realunit_wallet/styles/styles.dart';

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
              Icons.arrow_back_rounded,
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
                    settings: [
                      SettingOption(
                        title: S.of(context).settings_languages,
                        leading: LanguagesIcon(
                          size: 24,
                        ),
                        trailing: _forwardIcon,
                        selectedOption: state.language.name,
                        onTap: () => context.push('/settings/languages'),
                      ),
                      SettingOption(
                        title: S.of(context).settings_languages,
                        leading: CurrencyIcon(
                          size: 24,
                        ),
                        trailing: _forwardIcon,
                        selectedOption: state.language.name,
                        onTap: () => context.push('/settings/languages'),
                      ),
                      SettingOption(
                        title: S.of(context).settings_languages,
                        leading: DocumentReportIcon(
                          size: 24,
                        ),
                        trailing: _forwardIcon,
                        onTap: () => context.push('/settings/languages'),
                      ),
                      SettingOption(
                        title: "KYC Status",
                        leading: IdentificationIcon(
                          size: 24,
                        ),
                        trailing: _forwardIcon,
                        onTap: () => context.push('/settings/languages'),
                      ),
                      SettingOption(
                        title: "Nutzerdaten",
                        leading: UserCircleIcon(
                          size: 24,
                        ),
                        trailing: _forwardIcon,
                        onTap: () => context.push('/settings/languages'),
                      ),
                      SettingOption(
                        title: "Walletsicherung",
                        leading: KeySolidIcon(
                          size: 24,
                        ),
                        trailing: _forwardIcon,
                        onTap: () => context.push('/settings/languages'),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Divider(),
                ),
                SettingsSections(
                  settings: [
                    SettingOption(
                      title: "Geschäftsbeziehung beenden",
                      leading: XCircleIcon(size: 24),
                      onTap: () => context
                          .read<HomeBloc>()
                          .add(DeleteCurrentWalletEvent()),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}
