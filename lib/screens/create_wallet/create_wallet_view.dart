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
        backgroundColor: RealUnitColors.brand700,
        appBar: AppBar(),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: BlocBuilder<CreateWalletCubit, CreateWalletState>(
              builder: (context, state) {
                if (state.wallet != null) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 20, bottom: 20),
                        child: SvgPicture.asset(
                          'assets/images/backup_seed.svg',
                          width: 124,
                        ),
                      ),
                      Text(
                        S.of(context).createWalletTitle,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: RealUnitColors.realUnitBlack,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 3, bottom: 12),
                        child: Text(
                          S.of(context).createWalletSubtitle,
                          textAlign: TextAlign.center,
                          style: kSubtitleTextStyle,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
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
                                      S.of(context).createWalletRecoveryKeyTitle,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: RealUnitColors.realUnitBlack,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    S.of(context).createWalletRecoveryKeySubtitle,
                                    style: kSubtitleTextStyle,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SeedBlurCard(
                        seed: state.wallet!.seed,
                        onTap: context.read<CreateWalletCubit>().toggleShowSeed,
                        blur: state.hideSeed,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: CupertinoButton(
                          onPressed: () => _copySeed(state.wallet!.seed),
                          child: Text(
                            S.of(context).copySeed,
                            style: kPageTitleTextStyle.copyWith(color: RealUnitColors.realUnitBlue),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(top: 20, bottom: 20),
                        child: SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () =>
                                context.read<HomeBloc>().add(LoadWalletEvent(state.wallet!)),
                            style: kFullwidthBlueButtonStyle,
                            child: Text(
                              S.of(context).createWalletConfirm,
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
      );

  void _copySeed(String seed) => Clipboard.setData(ClipboardData(text: seed));
}
