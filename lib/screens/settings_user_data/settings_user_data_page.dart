import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_country_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_level.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_wallet_service.dart';
import 'package:realunit_wallet/screens/settings_user_data/cubit/settings_user_data_cubit.dart';
import 'package:realunit_wallet/screens/settings_user_data/subpages/edit_address/settings_edit_address_page.dart';
import 'package:realunit_wallet/screens/settings_user_data/subpages/edit_name/settings_edit_name_page.dart';
import 'package:realunit_wallet/screens/settings_user_data/subpages/edit_phone_number/settings_edit_phone_number_page.dart';
import 'package:realunit_wallet/styles/colors.dart';

class SettingsUserDataPage extends StatelessWidget {
  const SettingsUserDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsUserDataCubit(
        walletService: getIt<RealUnitWalletService>(),
        countryService: getIt<DfxCountryService>(),
        kycService: getIt<DfxKycService>(),
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
            SettingsUserDataSuccess(:final userData, :final pendingSteps) =>
              userData != null
                  ? SingleChildScrollView(
                      child: Padding(
                        padding: const .symmetric(horizontal: 12.0),
                        child: SafeArea(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 24,
                            children: [
                              _UserDataRow(
                                label: S.of(context).registerAccountType,
                                value: userData.type.name(context),
                              ),
                              _UserDataRow(
                                label: S.of(context).name,
                                value: userData.name,
                                statusLabel: pendingSteps.contains(KycStepName.nameChange)
                                    ? S.of(context).changeInReview
                                    : null,
                                onEdit: () async {
                                  final isEdited = await context.push<bool>(
                                    SettingsEditNamePage.routeName,
                                  );
                                  if (isEdited == true && context.mounted) {
                                    context.read<SettingsUserDataCubit>().getUserData();
                                  }
                                },
                              ),
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
                                onEdit: () async {
                                  final isEdited = await context.push<bool>(
                                    SettingsEditPhoneNumberPage.routeName,
                                  );
                                  if (isEdited == true && context.mounted) {
                                    context.read<SettingsUserDataCubit>().getUserData();
                                  }
                                },
                              ),
                              _UserDataRow(
                                label: S.of(context).residence,
                                value:
                                    '${userData.addressStreet}\n${userData.addressPostalCode} ${userData.addressCity}\n${userData.addressCountry.name}',
                                statusLabel: pendingSteps.contains(KycStepName.addressChange)
                                    ? S.of(context).changeInReview
                                    : null,
                                onEdit: () async {
                                  final isEdited = await context.push<bool>(
                                    SettingsEditAddressPage.routeName,
                                  );
                                  if (isEdited == true && context.mounted) {
                                    context.read<SettingsUserDataCubit>().getUserData();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
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
    this.onEdit,
    this.statusLabel,
  });

  final String label;
  final String value;
  final VoidCallback? onEdit;
  final String? statusLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: .spaceBetween,
      children: [
        Column(
          crossAxisAlignment: .start,
          spacing: 4,
          children: [
            Row(
              spacing: 8.0,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: .bold,
                    color: RealUnitColors.neutral900,
                  ),
                ),
                if (statusLabel != null)
                  Text(
                    statusLabel!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: RealUnitColors.realUnitBlue,
                      fontStyle: .italic,
                    ),
                  ),
              ],
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: RealUnitColors.neutral500,
              ),
            ),
          ],
        ),
        if (onEdit != null && statusLabel == null)
          IconButton.filledTonal(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
      ],
    );
  }
}
