import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/onboarding/onboarding_completed_page.dart';
import 'package:realunit_wallet/screens/restore_wallet/bloc/restore_wallet_cubit.dart';
import 'package:realunit_wallet/screens/restore_wallet/widgets/seed_editing_controller.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/styles.dart';
import 'package:realunit_wallet/widgets/text_divider.dart';

class RestoreWalletView extends StatelessWidget {
  RestoreWalletView({super.key}) : _controller = SeedEditingController();

  final TextEditingController _controller;

  @override
  Widget build(BuildContext context) => BlocListener<RestoreWalletCubit, RestoreWalletState>(
        listener: (context, state) {
          if (state.wallet != null) {
            context.push(OnboardingCompletedPage.route);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: Icon(
                Icons.arrow_back_rounded,
                size: 24,
              ),
            ),
          ),
          body: SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.only(left: 10, right: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      S.of(context).restore_wallet,
                      style: const TextStyle(fontSize: 20, color: RealUnitColors.realUnitBlack),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        S.of(context).restore_wallet_from_seed_description,
                        style: const TextStyle(fontSize: 15, color: DEuroColors.neutralGrey),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: TextField(
                        controller: _controller,
                        style: TextStyle(color: RealUnitColors.realUnitBlack),
                        decoration: InputDecoration(
                          hintText: "Seed",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: RealUnitColors.realUnitBlue),
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: RealUnitColors.realUnitBlue),
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                        ),
                        maxLines: null,
                        minLines: 4,
                        onChanged: context.read<RestoreWalletCubit>().validateSeed,
                      ),
                    ),
                    TextDivider(text: S.of(context).or.toUpperCase()),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () =>
                              context.read<RestoreWalletCubit>().restoreWalletFromSeedQR(context),
                          style: kFullwidthBlueButtonStyle,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(right: 5),
                                child: Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                S.of(context).restore_wallet_from_seed_qr,
                                textAlign: TextAlign.center,
                                style: kFullwidthBlueButtonTextStyle,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    BlocBuilder<RestoreWalletCubit, RestoreWalletState>(
                      builder: (context, state) => Padding(
                        padding: const EdgeInsets.only(top: 20, bottom: 20),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: state.isSeedReady && !state.isLoading
                                ? () => context
                                    .read<RestoreWalletCubit>()
                                    .restoreWallet(_controller.text)
                                : null,
                            style: kFullwidthBlueButtonStyle,
                            child: state.isLoading
                                ? CupertinoActivityIndicator(
                                    color: DEuroColors.dEuroGold,
                                  )
                                : Text(S.of(context).restore_wallet,
                                    textAlign: TextAlign.center,
                                    style: kFullwidthBlueButtonTextStyle),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
