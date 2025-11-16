import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/settings/widgets/settings_section.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/language.dart';
import 'package:realunit_wallet/styles/styles.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SettingsLanguagePage extends StatelessWidget {
  const SettingsLanguagePage({super.key});

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
        S.of(context).settings_languages,
        style: kPageTitleTextStyle,
      ),
      border: null,
    ),
    body: SingleChildScrollView(
      child: SizedBox(
        width: double.infinity,
        child: BlocBuilder<SettingsBloc, SettingsState>(
          bloc: getIt<SettingsBloc>(),
          builder: (context, state) => SettingsSections(
            settings: Language.values
                .map(
                  (lang) => SettingOption(
                title: lang.name,
                trailing: state.language == lang ? Icon(
                  Icons.check,
                  size: 20,
                  color: DEuroColors.dEuroBlue,
                ) : null,
                onTap: () => context
                    .read<SettingsBloc>()
                    .add(SetLanguageEvent(lang)),
              ),
            )
                .toList(),
          ),
        ),
      ),
    ),
  );
}
