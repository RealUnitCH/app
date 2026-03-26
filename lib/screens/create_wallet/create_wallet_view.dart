import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/create_wallet/bloc/create_wallet_cubit.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/seed_blur_card.dart';

class CreateWalletView extends StatelessWidget {
  const CreateWalletView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: RealUnitColors.brand700,
    appBar: AppBar(),
    body: SafeArea(
      child: Padding(
        padding: const .symmetric(horizontal: 20),
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
                          mainAxisAlignment: .start,
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
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: .bold,
                                  ),
                                ),
                                Text(
                                  S.of(context).createWalletSubtitle,
                                  textAlign: .center,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: RealUnitColors.neutral500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24.0),
                            SeedBlurCard(
                              seed: state.wallet!.seed,
                              onTap: context.read<CreateWalletCubit>().toggleShowSeed,
                              blur: state.hideSeed,
                            ),
                            const Spacer(),
                            Padding(
                              padding: const .symmetric(vertical: 20),
                              child: SizedBox(
                                width: .infinity,
                                child: FilledButton(
                                  onPressed: () => context.push(
                                    '/wallet/verifySeed',
                                    extra: state.wallet,
                                  ),
                                  child: Text(
                                    S.of(context).createWalletConfirm,
                                    textAlign: .center,
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
}
