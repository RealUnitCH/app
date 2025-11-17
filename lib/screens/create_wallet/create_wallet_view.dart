import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/create_wallet/bloc/create_wallet_cubit.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/icons.dart';
import 'package:realunit_wallet/styles/styles.dart';
import 'package:realunit_wallet/widgets/seed_blur_card.dart';

class CreateWalletView extends StatelessWidget {
  const CreateWalletView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: BlocBuilder<CreateWalletCubit, CreateWalletState>(
                builder: (context, state) {
                  if (state.wallet != null) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 20, bottom: 20),
                          child: SvgPicture.asset(
                            "assets/images/backup_seed.svg",
                            width: 155,
                          ),
                        ),
                        Text(
                          S.of(context).create_wallet_title,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: RealUnitColors.realUnitBlack,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 3, bottom: 20),
                          child: Text(
                            S.of(context).create_wallet_subtitle,
                            textAlign: TextAlign.center,
                            style: kSubtitleTextStyle,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(right: 10, top: 5),
                                child: RecoveryKeyIcon(
                                  size: 20,
                                  color: RealUnitColors.realUnitBlue,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 3),
                                      child: Text(
                                        S
                                            .of(context)
                                            .create_wallet_recovery_key_title,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: RealUnitColors.realUnitBlack,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      S
                                          .of(context)
                                          .create_wallet_recovery_key_subtitle,
                                      style: kSubtitleTextStyle,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SeedBlurCard(
                          text: state.wallet!.seed,
                          onTap:
                              context.read<CreateWalletCubit>().toggleShowSeed,
                          blur: state.hideSeed,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: CupertinoButton(
                            onPressed: () => _copySeed(state.wallet!.seed),
                            child: Text(
                              S.of(context).copy_seed,
                              style: kPageTitleTextStyle.copyWith(
                                  color: RealUnitColors.realUnitBlue),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.only(top: 20, bottom: 20),
                          child: SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () => context
                                  .read<HomeBloc>()
                                  .add(LoadWalletEvent(state.wallet!)),
                              style: kFullwidthBlueButtonStyle,
                              child: Text(
                                S.of(context).create_wallet_confirm,
                                textAlign: TextAlign.center,
                                style: kFullwidthBlueButtonTextStyle,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return const Center(
                    child: CupertinoActivityIndicator(
                      color: DEuroColors.dEuroGold,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

  Future<void> _copySeed(String seed) async =>
      Clipboard.setData(ClipboardData(text: seed));
}
