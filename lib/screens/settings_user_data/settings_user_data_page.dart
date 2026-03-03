import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_country_service.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_wallet_service.dart';
import 'package:realunit_wallet/screens/settings_user_data/cubit/settings_user_data_cubit.dart';
import 'package:realunit_wallet/styles/colors.dart';

class SettingsUserDataPage extends StatelessWidget {
  const SettingsUserDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsUserDataCubit(
        walletService: getIt<RealUnitWalletService>(),
        countryService: getIt<DfxCountryService>(),
      ),
      child: const SettingsUserDataView(),
    );
  }
}

class SettingsUserDataView extends StatelessWidget {
  const SettingsUserDataView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).userData),
      ),
      body: Container(
        padding: const .symmetric(horizontal: 20.0, vertical: 12.0),
        child: BlocBuilder<SettingsUserDataCubit, SettingsUserDataState>(
          builder: (context, state) => switch (state) {
            SettingsUserDataSuccess(:final userData) =>
              userData != null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 24,
                        children: [
                          _UserDataRow(
                            label: S.of(context).registerAccountType,
                            value: userData.type.name(context),
                          ),
                          _UserDataRow(label: S.of(context).name, value: userData.name),
                          _UserDataRow(
                            label: S.of(context).birthday,
                            value: DateFormat('dd.MM.yyyy').format(userData.birthday),
                          ),
                          _UserDataRow(
                            label: S.of(context).registerCitizenship,
                            value: userData.nationality.name,
                          ),
                          _UserDataRow(label: S.of(context).email, value: userData.email),
                          _UserDataRow(
                            label: S.of(context).phoneNumber,
                            value: userData.phoneNumber,
                          ),
                          _UserDataRow(
                            label: S.of(context).residence,
                            value:
                                '${userData.addressStreet}\n${userData.addressPostalCode} ${userData.addressCity}\n${userData.addressCountry.name}',
                          ),
                        ],
                      ),
                    )
                  : Center(
                      child: Text(S.of(context).userDataNotFound),
                    ),
            SettingsUserDataLoading() => const Center(
              child: CupertinoActivityIndicator(),
            ),
            SettingsUserDataFailure(:final message) => Center(
              child: Text(message),
            ),

            _ => const SizedBox.shrink(),
          },
        ),
      ),
    );
  }
}

class _UserDataRow extends StatelessWidget {
  const _UserDataRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      spacing: 4,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: RealUnitColors.neutral900,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: RealUnitColors.neutral500,
          ),
        ),
      ],
    );
  }
}
