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
      )..getUserData(),
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
          builder: (context, state) {
            if (state is SettingsUserDataSuccess) {
              final userData = state.userData;
              if (userData != null) {
                return Padding(
                  padding: const .symmetric(horizontal: 12.0),
                  child: Column(
                    crossAxisAlignment: .start,
                    spacing: 24,
                    children: [
                      Column(
                        crossAxisAlignment: .start,
                        spacing: 4,
                        children: [
                          Text(
                            S.of(context).registerAccountType,
                            style:
                                Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  fontWeight: .bold,
                                  color: RealUnitColors.neutral900,
                                ),
                          ),
                          Text(
                            userData.type.name(context),
                            style:
                                Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  color: RealUnitColors.neutral500,
                                ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: .start,
                        spacing: 4,
                        children: [
                          Text(
                            S.of(context).name,
                            style:
                                Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  fontWeight: .bold,
                                  color: RealUnitColors.neutral900,
                                ),
                          ),
                          Text(
                            userData.name,
                            style:
                                Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  color: RealUnitColors.neutral500,
                                ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: .start,
                        spacing: 4,
                        children: [
                          Text(
                            S.of(context).birthday,
                            style:
                                Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  fontWeight: .bold,
                                  color: RealUnitColors.neutral900,
                                ),
                          ),
                          Text(
                            DateFormat('dd.MM.yyyy').format(userData.birthday),
                            style:
                                Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  color: RealUnitColors.neutral500,
                                ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: .start,
                        spacing: 4,
                        children: [
                          Text(
                            S.of(context).registerCitizenship,
                            style:
                                Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  fontWeight: .bold,
                                  color: RealUnitColors.neutral900,
                                ),
                          ),
                          Text(
                            userData.nationality.name,
                            style:
                                Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  color: RealUnitColors.neutral500,
                                ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: .start,
                        spacing: 4,
                        children: [
                          Text(
                            S.of(context).email,
                            style:
                                Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  fontWeight: .bold,
                                  color: RealUnitColors.neutral900,
                                ),
                          ),
                          Text(
                            userData.email,
                            style:
                                Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  color: RealUnitColors.neutral500,
                                ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: .start,
                        spacing: 4,
                        children: [
                          Text(
                            S.of(context).phoneNumber,
                            style:
                                Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  fontWeight: .bold,
                                  color: RealUnitColors.neutral900,
                                ),
                          ),
                          Text(
                            userData.phoneNumber,
                            style:
                                Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  color: RealUnitColors.neutral500,
                                ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: .start,
                        spacing: 4,
                        children: [
                          Text(
                            S.of(context).residence,
                            style:
                                Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  fontWeight: .bold,
                                  color: RealUnitColors.neutral900,
                                ),
                          ),
                          Text(
                            '${userData.addressStreet}\n${userData.addressPostalCode} ${userData.addressCity}\n${userData.addressCountry.name}',
                            style:
                                Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  color: RealUnitColors.neutral500,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }
              return Center(
                child: Text('Es sind noch keine User Daten hinterlegt.'),
              );
            }
            if (state is SettingsUserDataLoading) {
              return const Center(
                child: CupertinoActivityIndicator(),
              );
            }
            if (state is SettingsUserDataFailure) {
              return Center(
                child: Text(state.message),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
