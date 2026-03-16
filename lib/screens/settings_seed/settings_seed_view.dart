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
          padding: const .symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: .start,
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
                    textAlign: .center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    S.of(context).settingsWalletBackupSubtitle1,
                    textAlign: .center,
                    style:
                        Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(
                          color: RealUnitColors.neutral500,
                        ),
                  ),
                  Text(
                    S.of(context).settingsWalletBackupSubtitle2,
                    textAlign: .center,
                    style:
                        Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(
                          color: RealUnitColors.neutral500,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Row(
                spacing: 10,
                crossAxisAlignment: .center,
                children: [
                  const RecoveryKeyIcon(
                    size: 20,
                    color: RealUnitColors.realUnitBlue,
                  ),
                  Expanded(
                    child: Text(
                      S.of(context).createWalletRecoveryKeyTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
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
