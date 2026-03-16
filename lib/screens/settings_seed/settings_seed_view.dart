import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/settings_seed/bloc/settings_seed_cubit.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/icons.dart';
import 'package:realunit_wallet/widgets/seed_blur_card.dart';

class SettingsSeedView extends StatelessWidget {
  const SettingsSeedView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SvgPicture.asset(
                'assets/images/illustrations/backup_wallet.svg',
                height: 124,
              ),
              const SizedBox(height: 28),
              Column(
                spacing: 8.0,
                children: [
                  Text(
                    S.of(context).settingsWalletBackup,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      height: 30 / 26,
                      letterSpacing: -0.52,
                    ),
                  ),
                  Text(
                    S.of(context).settingsWalletBackupSubtitle1,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: RealUnitColors.neutral500,
                      fontSize: 14,
                      height: 18 / 14,
                    ),
                  ),
                  Text(
                    S.of(context).settingsWalletBackupSubtitle2,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: RealUnitColors.neutral500,
                      fontSize: 14,
                      height: 18 / 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Row(
                spacing: 10,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const RecoveryKeyIcon(size: 20, color: RealUnitColors.realUnitBlue),
                  Text(
                    S.of(context).createWalletRecoveryKeyTitle,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                      height: 24 / 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              BlocBuilder<SettingsSeedCubit, SettingsSeedState>(
                builder: (context, state) {
                  return SeedBlurCard(
                    seed: context.read<SettingsSeedCubit>().state.seed,
                    onTap: () => context.read<SettingsSeedCubit>().toggleShowSeed(),
                    blur: !context.read<SettingsSeedCubit>().state.showSeed,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
