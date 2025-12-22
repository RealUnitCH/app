import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/settings_seed/bloc/settings_seed_cubit.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/icons.dart';
import 'package:realunit_wallet/styles/styles.dart';
import 'package:realunit_wallet/widgets/seed_blur_card.dart';

class SettingsSeedView extends StatelessWidget {
  const SettingsSeedView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: RealUnitColors.realUnitBlack,
              size: 24,
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SvgPicture.asset(
                    "assets/images/backup_seed.svg",
                    height: 124,
                  ),
                  SizedBox(height: 20),
                  Text(
                    S.of(context).settings_wallet_backup,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      height: 30 / 26,
                      letterSpacing: -0.52,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    S.of(context).settings_wallet_backup_subtitle_1,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: RealUnitColors.neutral500,
                      fontSize: 14,
                      height: 18 / 14,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    S.of(context).settings_wallet_backup_subtitle_2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: RealUnitColors.neutral500,
                      fontSize: 14,
                      height: 18 / 14,
                    ),
                  ),
                  SizedBox(height: 40),
                  Row(
                    spacing: 10,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      RecoveryKeyIcon(size: 20, color: RealUnitColors.realUnitBlue),
                      Text(
                        S.of(context).create_wallet_recovery_key_title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                          height: 24 / 20,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  BlocBuilder<SettingsSeedCubit, SettingsSeedState>(
                    builder: (context, state) {
                      return Column(
                        spacing: 4,
                        children: [
                          SeedBlurCard(
                            seed: context.read<SettingsSeedCubit>().state.seed,
                            onTap: () => context.read<SettingsSeedCubit>().toggleShowSeed(),
                            blur: !context.read<SettingsSeedCubit>().state.showSeed,
                          ),
                          TextButton(
                            onPressed: () => Clipboard.setData(
                                ClipboardData(text: context.read<SettingsSeedCubit>().state.seed)),
                            child: Text(
                              S.of(context).copy_seed,
                              style:
                                  kPageTitleTextStyle.copyWith(color: RealUnitColors.realUnitBlue),
                            ),
                          ),
                        ],
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
