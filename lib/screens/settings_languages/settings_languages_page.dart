import 'dart:developer' as developer;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/repository/supported_language_repository.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/settings/widgets/settings_section.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/language.dart';

class SettingsLanguagePage extends StatefulWidget {
  const SettingsLanguagePage({super.key});

  @override
  State<SettingsLanguagePage> createState() => _SettingsLanguagePageState();
}

class _SettingsLanguagePageState extends State<SettingsLanguagePage> {
  late Future<List<Language>> _future;

  @override
  void initState() {
    super.initState();
    _future = getIt<SupportedLanguageRepository>().getEnabled();
  }

  void _retry() {
    setState(() {
      _future = getIt<SupportedLanguageRepository>().getEnabled();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(S.of(context).settingsLanguages)),
    body: FutureBuilder<List<Language>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          developer.log(
            'SettingsLanguagePage: failed to load languages',
            name: 'realunit_wallet.settings',
            error: snapshot.error,
            stackTrace: snapshot.stackTrace,
            level: 1000, // SEVERE
          );
          return _LanguageErrorView(
            key: const Key('settings-languages-error'),
            title: S.of(context).settingsLanguageLoadFailed,
            description: S.of(context).settingsLanguageLoadFailedDescription,
            onRetry: _retry,
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CupertinoActivityIndicator());
        }
        final languages = snapshot.data!;
        return SingleChildScrollView(
          child: SizedBox(
            width: double.infinity,
            child: BlocBuilder<SettingsBloc, SettingsState>(
              bloc: getIt<SettingsBloc>(),
              builder: (context, state) => SettingsSections(
                settings: languages
                    .map(
                      (lang) => SettingOption(
                        title: lang.name,
                        trailing: state.language == lang
                            ? const Icon(
                                Icons.check,
                                size: 20,
                                color: RealUnitColors.realUnitBlue,
                              )
                            : null,
                        onTap: () => context.read<SettingsBloc>().add(SetLanguageEvent(lang)),
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

class _LanguageErrorView extends StatelessWidget {
  const _LanguageErrorView({
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
