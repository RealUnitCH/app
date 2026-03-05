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
              return LayoutBuilder(
                builder: (context, constraint) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraint.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SvgPicture.asset(
                              'assets/images/illustrations/backup_wallet.svg',
                              width: 124,
                            ),
                            const SizedBox(height: 28),
                            Column(
                              spacing: 8.0,
                              children: [
                                Text(
                                  S.of(context).createWalletTitle,
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    color: RealUnitColors.realUnitBlack,
                                    letterSpacing: -0.52,
                                    height: 30 / 26,
                                  ),
                                ),
                                Text(
                                  S.of(context).createWalletSubtitle,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: RealUnitColors.neutral500,
                                    height: 18 / 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 40.0),
                            Row(
                              spacing: 8.0,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const RecoveryKeyIcon(
                                  size: 20,
                                  color: RealUnitColors.realUnitBlue,
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
                                            fontSize: 20,
                                            color: RealUnitColors.realUnitBlack,
                                            fontWeight: FontWeight.bold,
                                            height: 24 / 20,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        S.of(context).createWalletRecoveryKeySubtitle,
                                        style: const TextStyle(
                                          color: RealUnitColors.neutral500,
                                          height: 18 / 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 16,
                            ),
                            Column(
                              children: [
                                SeedBlurCard(
                                  seed: state.wallet!.seed,
                                  onTap: context.read<CreateWalletCubit>().toggleShowSeed,
                                  blur: state.hideSeed,
                                ),
                                CupertinoButton(
                                  onPressed: () => _copySeed(state.wallet!.seed),
                                  child: Text(
                                    S.of(context).copySeed,
                                    style: kPageTitleTextStyle.copyWith(
                                      color: RealUnitColors.realUnitBlue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: () =>
                                      context.read<HomeBloc>().add(LoadWalletEvent(state.wallet!)),
                                  child: Text(
                                    S.of(context).createWalletConfirm,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }
            return const Center(
              child: CupertinoActivityIndicator(),
            );
          },
        ),
      ),
    ),
  );

  void _copySeed(String seed) => Clipboard.setData(ClipboardData(text: seed));
}
