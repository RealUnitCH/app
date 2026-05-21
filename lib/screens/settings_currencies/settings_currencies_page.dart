import 'dart:developer' as developer;

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

class SettingsCurrenciesPage extends StatefulWidget {
  const SettingsCurrenciesPage({super.key});

  @override
  State<SettingsCurrenciesPage> createState() => _SettingsCurrenciesPageState();
}

class _SettingsCurrenciesPageState extends State<SettingsCurrenciesPage> {
  late Future<List<Currency>> _future;

  @override
  void initState() {
    super.initState();
    _future = getIt<SupportedFiatRepository>().getAll();
  }

  void _retry() {
    setState(() {
      _future = getIt<SupportedFiatRepository>().getAll();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        S.of(context).settingsCurrency,
      ),
    ),
    body: FutureBuilder<List<Currency>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          developer.log(
            'SettingsCurrenciesPage: failed to load currencies',
            name: 'realunit_wallet.settings',
            error: snapshot.error,
            stackTrace: snapshot.stackTrace,
            level: 1000, // SEVERE
          );
          return _ErrorView(
            key: const Key('settings-currencies-error'),
            title: S.of(context).settingsCurrencyLoadFailed,
            description: S.of(context).settingsCurrencyLoadFailedDescription,
            onRetry: _retry,
          );
        }
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

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    super.key,
    required this.title,
    required this.description,
    required this.onRetry,
  });

  final String title;
  final String description;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: RealUnitColors.neutral500,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(color: RealUnitColors.neutral500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onRetry,
            child: Text(S.of(context).retry),
          ),
        ],
      ),
    ),
  );
}
