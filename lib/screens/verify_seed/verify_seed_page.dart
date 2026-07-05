import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:realunit_wallet/packages/utils/screenshot_guard.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/verify_seed/cubit/verify_seed_cubit.dart';
import 'package:realunit_wallet/screens/verify_seed/widgets/verify_seed_button.dart';
import 'package:realunit_wallet/screens/verify_seed/widgets/verify_seed_input_field.dart';
import 'package:realunit_wallet/setup/di.dart';
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
    child: const VerifySeedView(),
  );
}

class VerifySeedView extends StatefulWidget {
  const VerifySeedView({super.key});

  @override
  State<VerifySeedView> createState() => _VerifySeedViewState();
}

class _VerifySeedViewState extends State<VerifySeedView> {
  // @no-integration-test: no_screenshot suppresses the OS screenshot /
  // app-switcher thumbnail / screen-recording via a platform channel — the
  // real effect is only observable on a device, not in a widget/golden test.
  @override
  void initState() {
    // Seed words are entered/visible here — block screenshots and the
    // app-switcher snapshot like the other seed screens. Re-enabled on dispose
    // so other screens stay screenshot-able.
    ScreenshotGuard.acquire();
    super.initState();
  }

  @override
  void dispose() {
    ScreenshotGuard.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RealUnitColors.brand700,
      appBar: AppBar(),
      body: Padding(
        padding: const .symmetric(horizontal: 20),
        child: BlocConsumer<VerifySeedCubit, VerifySeedState>(
          listener: (context, state) async {
            if (state.isVerified) {
              await Future.delayed(const Duration(seconds: 2));
              if (context.mounted) {
                // Load the *committed* wallet (`state.committedWallet`), not
                // the page's draft (`id == 0`). `committedWallet` is only
                // ever set together with `isVerified`, so it is non-null
                // here. `LoadWalletEvent` makes `HomeBloc` set
                // `hasWallet: true`, which `main.dart`'s `_navigate()` needs
                // to route forward to onboarding-completed instead of
                // looping back to welcome.
                context.read<HomeBloc>().add(
                  LoadWalletEvent(state.committedWallet!),
                );
              }
            }
          },
          builder: (context, state) {
            if (state.wordIndices.isNotEmpty) {
              return LayoutBuilder(
                builder: (context, constraint) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraint.maxHeight),
                      child: IntrinsicHeight(
                        child: SafeArea(
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
                                    style: Theme.of(context).textTheme.headlineSmall,
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
                                enteredWords: state.enteredWords,
                                hasError: state.hasError,
                              ),
                              const Spacer(),
                              const VerifySeedButton(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
