import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_country_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_level.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_wallet_service.dart';
import 'package:realunit_wallet/screens/hardware_connect_bitbox/show_bitbox_reconnect_sheet.dart';
import 'package:realunit_wallet/screens/settings_user_data/cubit/settings_user_data_cubit.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/setup/routing/routes/settings_routes.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';

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
            SettingsUserDataSuccess(:final userData, :final email, :final pendingSteps, :final capabilities) =>
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
                                onEdit: capabilities.canEditName
                                    ? () async {
                                        final isEdited = await context.pushNamed<bool>(
                                          SettingsRoutes.editName,
                                        );
                                        if (isEdited == true && context.mounted) {
                                          context.read<SettingsUserDataCubit>().getUserData();
                                        }
                                      }
                                    : null,
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
                                onEdit: capabilities.canEditPhone
                                    ? () async {
                                        final isEdited = await context.pushNamed<bool>(
                                          SettingsRoutes.editPhone,
                                        );
                                        if (isEdited == true && context.mounted) {
                                          context.read<SettingsUserDataCubit>().getUserData();
                                        }
                                      }
                                    : null,
                              ),
                              _UserDataRow(
                                label: S.of(context).residence,
                                value:
                                    '${userData.addressStreet}\n${userData.addressPostalCode} ${userData.addressCity}\n${userData.addressCountry.name}',
                                statusLabel: pendingSteps.contains(KycStepName.addressChange)
                                    ? S.of(context).changeInReview
                                    : null,
                                onEdit: capabilities.canEditAddress
                                    ? () async {
                                        final isEdited = await context.pushNamed<bool>(
                                          SettingsRoutes.editAddress,
                                        );
                                        if (isEdited == true && context.mounted) {
                                          context.read<SettingsUserDataCubit>().getUserData();
                                        }
                                      }
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : email != null
                  ? SafeArea(
                      child: Padding(
                        padding: const .symmetric(horizontal: 12.0),
                        child: _UserDataRow(
                          label: S.of(context).email,
                          value: email,
                        ),
                      ),
                    )
                  : Center(
                      child: Text(S.of(context).userDataNotFound),
                    ),
            SettingsUserDataLoading() => const Center(
              child: CupertinoActivityIndicator(),
            ),
            SettingsUserDataBitboxDisconnected() => _BitboxDisconnectedView(
              onReconnected: () => context.read<SettingsUserDataCubit>().getUserData(),
            ),
            SettingsUserDataFailure() => Center(
              child: Text(S.of(context).userDataLoadFailed),
            ),

            _ => const SizedBox.shrink(),
          },
        ),
      ),
    );
  }
}

class _BitboxDisconnectedView extends StatelessWidget {
  const _BitboxDisconnectedView({required this.onReconnected});

  final VoidCallback onReconnected;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            Text(
              S.of(context).bitboxDisconnectedTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              S.of(context).bitboxDisconnectedDescription,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: RealUnitColors.neutral500,
              ),
            ),
            AppFilledButton(
              onPressed: () async {
                await showBitboxReconnectSheet(context);
                onReconnected();
              },
              label: S.of(context).bitboxReconnect,
            ),
          ],
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
        // `onEdit == null` is now the authoritative signal: the cubit only
        // wires it up when `UserCapabilitiesDto.canEdit*` is true. The
        // status label (e.g. "Change in review") stays as an informational
        // badge alongside the Edit button — no extra gating here.
        if (onEdit != null)
          IconButton.filledTonal(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
      ],
    );
  }
}
