import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/verify_seed/cubit/verify_seed_cubit.dart';
import 'package:realunit_wallet/screens/verify_seed/widgets/verify_seed_input_field.dart';
import 'package:realunit_wallet/styles/colors.dart';

class VerifySeedPage extends StatelessWidget {
  const VerifySeedPage({super.key, required this.wallet});

  final SoftwareWallet wallet;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => VerifySeedCubit(
      wallet,
      getIt<WalletService>(),
    ),
    child: VerifySeedView(wallet: wallet),
  );
}

class VerifySeedView extends StatelessWidget {
  final SoftwareWallet wallet;

  const VerifySeedView({super.key, required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RealUnitColors.brand700,
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const .symmetric(horizontal: 20),
          child: BlocConsumer<VerifySeedCubit, VerifySeedState>(
            listener: (context, state) {
              if (state.isVerified) {
                context.read<HomeBloc>().add(
                  LoadWalletEvent(wallet),
                );
              }
            },
            builder: (context, state) {
              if (state.wordIndices.isEmpty) {
                return const SizedBox.shrink();
              }
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
                                  S.of(context).verifySeedTitle,
                                  style: Theme.of(context).textTheme.headlineMedium,
                                  textAlign: .center,
                                ),
                                Text(
                                  S.of(context).verifySeedSubtitle,
                                  textAlign: .center,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: RealUnitColors.neutral500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                            VerifySeedInputField(
                              wordIndices: state.wordIndices,
                              hasError: state.hasError,
                            ),
                            const Spacer(),
                            Padding(
                              padding: const .symmetric(vertical: 20),
                              child: SizedBox(
                                width: .infinity,
                                child: FilledButton(
                                  onPressed: state.canVerify
                                      ? () => context.read<VerifySeedCubit>().verify()
                                      : null,
                                  child: Text(
                                    S.of(context).confirm,
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
            },
          ),
        ),
      ),
    );
  }
}
