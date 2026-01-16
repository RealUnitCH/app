import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/settings/widgets/settings_section.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/currency.dart';
import 'package:realunit_wallet/styles/styles.dart';

class SettingsCurrenciesPage extends StatelessWidget {
  const SettingsCurrenciesPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(
            S.of(context).settingsCurrency,
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
                settings: Currency.values
                    .map(
                      (currency) => SettingOption(
                        title: currency.code,
                        subtitle: currency.name,
                        trailing: state.currency == currency
                            ? const Icon(
                                Icons.check,
                                size: 20,
                                color: RealUnitColors.realUnitBlue,
                              )
                            : null,
                        onTap: () => context.read<SettingsBloc>().add(SetCurrencyEvent(currency)),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      );
}
