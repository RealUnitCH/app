import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/repository/supported_fiat_repository.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/settings/widgets/settings_section.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/currency.dart';

class SettingsCurrenciesPage extends StatelessWidget {
  const SettingsCurrenciesPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        S.of(context).settingsCurrency,
      ),
    ),
    body: FutureBuilder<List<Currency>>(
      future: getIt<SupportedFiatRepository>().getAll(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CupertinoActivityIndicator());
        }
        final currencies = snapshot.data!;
        return SingleChildScrollView(
          child: SizedBox(
            width: double.infinity,
            child: BlocBuilder<SettingsBloc, SettingsState>(
              bloc: getIt<SettingsBloc>(),
              builder: (context, state) => SettingsSections(
                settings: currencies
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
        );
      },
    ),
  );
}
