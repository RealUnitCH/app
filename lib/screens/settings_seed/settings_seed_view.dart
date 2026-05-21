import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/settings_seed/bloc/settings_seed_cubit.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/icons.dart';
import 'package:realunit_wallet/widgets/seed_blur_card.dart';

class SettingsSeedView extends StatefulWidget {
  const SettingsSeedView({super.key});

  @override
  State<SettingsSeedView> createState() => _SettingsSeedViewState();
}

class _SettingsSeedViewState extends State<SettingsSeedView> {
  @override
  void initState() {
    NoScreenshot.instance.screenshotOff();
    super.initState();
  }

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
                  // The cubit starts with an empty seed when the wallet is a
                  // SoftwareViewWallet (the default production state after
                  // #461) and only fills it in after the async unlock. Until
                  // the 12 words are in memory, MnemonicReadOnlyField's
                  // `length == 12` assert would crash this screen — show a
                  // spinner instead and rebuild once the seed lands.
                  final wordCount = state.seed.split(' ').where((w) => w.isNotEmpty).length;
                  if (wordCount != 12) {
                    return const Center(child: CupertinoActivityIndicator());
                  }
                  return SeedBlurCard(
                    seed: state.seed,
                    onTap: () => context.read<SettingsSeedCubit>().toggleShowSeed(),
                    blur: !state.showSeed,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );

  @override
  void dispose() {
    NoScreenshot.instance.screenshotOn();
    super.dispose();
  }
}
