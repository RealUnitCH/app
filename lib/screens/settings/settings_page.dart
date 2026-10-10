import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/generated/release_info.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_referral_service.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/pin/verify_pin_page.dart';
import 'package:realunit_wallet/screens/referral/cubit/referral_eligibility_cubit.dart';
import 'package:realunit_wallet/screens/referral/widgets/referral_eligibility_resume.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/settings/widgets/settings_confirm_logout_wallet_sheet.dart';
import 'package:realunit_wallet/screens/settings/widgets/settings_section.dart';
import 'package:realunit_wallet/screens/settings/widgets/settings_version_unlock.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/setup/routing/routes/pin_routes.dart';
import 'package:realunit_wallet/setup/routing/routes/settings_routes.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/icons.dart';

// The Settings Network row exists only while insider network options are on.
bool showSettingsNetworkRow({required bool networkOptionsEnabled}) =>
    networkOptionsEnabled;

// Paired or not is a local BitBox limit. A stored balance does not hide this row.
bool showHardwareWalletRow({required bool bitboxPaired}) => !bitboxPaired;

bool showMoveBalanceRow({
  required bool hasSoftware,
  required bool hasBitbox,
}) => hasSoftware && hasBitbox;

class SettingsPage extends StatelessWidget {
  final Duration unavailablePollInterval;

  const SettingsPage({
    super.key,
    this.unavailablePollInterval = const Duration(seconds: 15),
  });

  static const _forwardIcon = Icon(
    Icons.arrow_forward_ios,
    size: 20,
    color: RealUnitColors.realUnitBlack,
  );

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => ReferralEligibilityCubit(getIt<RealUnitReferralService>())..load(),
    child: ReferralEligibilityResumeReloader(
      unavailablePollInterval: unavailablePollInterval,
      child: Scaffold(
        appBar: AppBar(title: Text(S.of(context).settings)),
        body: SingleChildScrollView(
          child: Column(
            children: [
              BlocBuilder<SettingsBloc, SettingsState>(
                bloc: getIt<SettingsBloc>(),
                builder: (context, state) =>
                    BlocBuilder<ReferralEligibilityCubit, ReferralEligibilityState>(
                      builder: (context, eligibility) => FutureBuilder<_HardwareWalletFlags>(
                        future: _loadHardwareWalletFlags(
                          walletService: getIt<WalletService>(),
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            throw snapshot.error!;
                          }
                          final flags = snapshot.data;
                          return SettingsSections(
                        settings: [
                          SettingOption(
                            title: S.of(context).settingsLanguages,
                            leading: const LanguagesIcon(size: 24),
                            trailing: _forwardIcon,
                            selectedOption: state.language.name,
                            onTap: () => context.pushNamed(SettingsRoutes.languages),
                          ),
                          SettingOption(
                            title: S.of(context).settingsCurrency,
                            leading: const CurrencyIcon(size: 24),
                            trailing: _forwardIcon,
                            selectedOption: state.currency.code,
                            onTap: () => context.pushNamed(SettingsRoutes.currencies),
                          ),
                          if (showSettingsNetworkRow(
                            networkOptionsEnabled: state.networkOptionsEnabled,
                          ))
                            SettingOption(
                              title: S.of(context).settingsNetwork,
                              leading: const NodesIcon(size: 24),
                              trailing: _forwardIcon,
                              selectedOption: state.networkMode.localizedName(
                                context,
                              ),
                              onTap: () => context.pushNamed(SettingsRoutes.network),
                            ),
                          SettingOption(
                            title: S.of(context).settingsTaxReport,
                            leading: const DocumentReportIcon(size: 24),
                            trailing: _forwardIcon,
                            onTap: () => context.pushNamed(SettingsRoutes.taxReport),
                          ),
                          if (eligibility is ReferralEligibilityLoaded &&
                              eligibility.eligible &&
                              state.walletFeatureReferral)
                            SettingOption(
                              title: S.of(context).referrals,
                              subtitle: S.of(context).referralsSubtitle,
                              leading: const ExcludeSemantics(
                                child: Icon(
                                  Icons.card_giftcard_outlined,
                                  size: 24,
                                  color: RealUnitColors.realUnitBlue,
                                ),
                              ),
                              trailing: _forwardIcon,
                              onTap: () => context.pushNamed(SettingsRoutes.referral),
                            ),
                          SettingOption(
                            title: S.of(context).userData,
                            leading: const UserCircleIcon(size: 24),
                            trailing: _forwardIcon,
                            onTap: () => context.pushNamed(SettingsRoutes.userData),
                          ),
                          SettingOption(
                            title: S.of(context).legalDocuments,
                            leading: const Icon(
                              Icons.description_rounded,
                              size: 24,
                              color: RealUnitColors.realUnitBlue,
                            ),
                            trailing: _forwardIcon,
                            onTap: () => context.pushNamed(SettingsRoutes.legalDocuments),
                          ),
                          SettingOption(
                            title: S.of(context).contact,
                            leading: const Icon(
                              Icons.info_rounded,
                              color: RealUnitColors.realUnitBlue,
                            ),
                            trailing: _forwardIcon,
                            onTap: () => context.pushNamed(SettingsRoutes.contact),
                          ),
                          SettingOption(
                            title: S.of(context).settingsSecurity,
                            leading: const Icon(
                              Icons.shield_outlined,
                              size: 24,
                              color: RealUnitColors.realUnitBlue,
                            ),
                            trailing: _forwardIcon,
                            onTap: () => context.pushNamed(SettingsRoutes.security),
                          ),
                          SettingOption(
                            title: S.of(context).walletAddress,
                            leading: const RealUnitIcon(size: 24),
                            trailing: _forwardIcon,
                            onTap: () => context.pushNamed(SettingsRoutes.walletAddress),
                          ),
                          if (flags != null &&
                              showHardwareWalletRow(bitboxPaired: flags.bitboxPaired))
                            SettingOption(
                              title: S.of(context).settingsHardwareWallet,
                              leading: const Icon(
                                Icons.developer_board_outlined,
                                size: 24,
                                color: RealUnitColors.realUnitBlue,
                              ),
                              trailing: _forwardIcon,
                              onTap: () => context.pushNamed(
                                SettingsRoutes.hardwareWalletIntro,
                              ),
                            ),
                          if (flags != null &&
                              showMoveBalanceRow(
                                hasSoftware: flags.hasSoftware,
                                hasBitbox: flags.hasBitbox,
                              ))
                            SettingOption(
                              title: S.of(context).settingsMoveBalance,
                              leading: const Icon(
                                Icons.swap_horiz,
                                size: 24,
                                color: RealUnitColors.realUnitBlue,
                              ),
                              trailing: _forwardIcon,
                              onTap: () => context.pushNamed(SettingsRoutes.moveBalance),
                            ),
                          if (state.insiderFeaturesUnlocked)
                            SettingOption(
                              title: S.of(context).settingsInsiderFeatures,
                              leading: const Icon(
                                Icons.science_outlined,
                                size: 24,
                                color: RealUnitColors.realUnitBlue,
                              ),
                              trailing: _forwardIcon,
                              onTap: () => context.pushNamed(SettingsRoutes.insider),
                            ),
                          if (context.read<HomeBloc>().state.openWallet?.walletType ==
                              WalletType.software)
                            SettingOption(
                              title: S.of(context).settingsWalletBackup,
                              leading: const KeySolidIcon(size: 24),
                              trailing: _forwardIcon,
                              onTap: () => context.pushNamed(
                                PinRoutes.gate,
                                extra: VerifyPinParams(
                                  onAuthenticated: () =>
                                      context.pushReplacementNamed(SettingsRoutes.seed),
                                  description: S.of(context).pinVerifySeedDescription,
                                ),
                              ),
                            ),
                        ],
                          );
                        },
                      ),
                    ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Divider(color: RealUnitColors.neutral200),
              ),
              SettingsSections(
                settings: [
                  SettingOption(
                    title: S.of(context).settingsDeleteWallet,
                    leading: const XCircleIcon(size: 24),
                    onTap: () async {
                      bool? isLogout = await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => const SettingsConfirmLogoutWalletSheet(),
                      );
                      if (isLogout ?? false) {
                        await Future.delayed(const Duration(milliseconds: 300));
                        if (context.mounted) {
                          context.read<HomeBloc>().add(
                            const DeleteCurrentWalletEvent(),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
              const SettingsVersionUnlock(releaseTag: releaseTag),
            ],
          ),
        ),
      ),
    ),
  );
}

class _HardwareWalletFlags {
  final bool bitboxPaired;
  final bool hasSoftware;
  final bool hasBitbox;

  const _HardwareWalletFlags({
    required this.bitboxPaired,
    required this.hasSoftware,
    required this.hasBitbox,
  });
}

Future<_HardwareWalletFlags> _loadHardwareWalletFlags({
  required WalletService walletService,
}) async {
  final wallets = await walletService.listWallets();
  var hasSoftware = false;
  var hasBitbox = false;
  for (final wallet in wallets) {
    if (wallet.walletType == WalletType.software) {
      hasSoftware = true;
    } else if (wallet.walletType == WalletType.bitbox) {
      hasBitbox = true;
    }
  }
  return _HardwareWalletFlags(
    bitboxPaired: hasBitbox,
    hasSoftware: hasSoftware,
    hasBitbox: hasBitbox,
  );
}
