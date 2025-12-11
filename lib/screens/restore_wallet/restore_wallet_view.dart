import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/restore_wallet/bloc/restore_wallet_cubit.dart';
import 'package:realunit_wallet/screens/restore_wallet/cubit/validate_seed_cubit.dart';
import 'package:realunit_wallet/screens/restore_wallet/widgets/mnemonic_input_field.dart';
import 'package:realunit_wallet/screens/restore_wallet/widgets/mnemonic_input_field_controller.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/styles.dart';
import 'package:realunit_wallet/widgets/text_substring_highlighting.dart';

class RestoreWalletView extends StatelessWidget {
  RestoreWalletView({super.key});

  final _controllers = List.generate(12, (_) => MnemonicInputFieldController());
  final _focusNodes = List.generate(12, (_) => FocusNode());

  @override
  Widget build(BuildContext context) => BlocListener<RestoreWalletCubit, RestoreWalletState>(
        listenWhen: (previous, current) => previous.wallet != current.wallet,
        listener: (context, state) {
          if (state.wallet != null) {
            context.read<HomeBloc>().add(LoadWalletEvent(state.wallet!));
          }
        },
        child: Scaffold(
          backgroundColor: RealUnitColors.brand700,
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
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: LayoutBuilder(
                  builder: (context, constraint) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraint.maxHeight),
                        child: IntrinsicHeight(
                          child: Column(
                            children: <Widget>[
                              SvgPicture.asset(
                                "assets/images/restore_wallet.svg",
                                height: 124,
                              ),
                              SizedBox(
                                height: 20,
                              ),
                              Text(
                                S.of(context).restore_wallet,
                                style: const TextStyle(
                                  fontSize: 26,
                                  color: RealUnitColors.realUnitBlack,
                                  fontWeight: FontWeight.bold,
                                  height: 30 / 26,
                                  letterSpacing: -0.52,
                                ),
                              ),
                              SizedBox(
                                height: 40,
                              ),
                              Row(
                                spacing: 8.0,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                                    child: Icon(
                                      Icons.key_rounded,
                                      size: 20.0,
                                      color: RealUnitColors.realUnitBlue,
                                    ),
                                  ),
                                  Expanded(
                                    child: TextSubstringHighlighting(
                                      text: S.of(context).restore_wallet_from_seed_description,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: RealUnitColors.neutral500,
                                      ),
                                      highlightedText: '12 ${S.of(context).recovery_words}',
                                    ),
                                  )
                                ],
                              ),
                              SizedBox(height: 16),
                              MnemonicInput(
                                controllers: _controllers,
                                focusNodes: _focusNodes,
                                onChanged: () =>
                                    context.read<ValidateSeedCubit>().validateSeed(_getSeed),
                              ),
                              Spacer(),
                              BlocBuilder<ValidateSeedCubit, ValidateSeedState>(
                                builder: (context, valid) =>
                                    BlocBuilder<RestoreWalletCubit, RestoreWalletState>(
                                  builder: (context, restoreState) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 20),
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: TextButton(
                                          onPressed: valid == ValidateSeedState.valid
                                              ? () => context
                                                  .read<RestoreWalletCubit>()
                                                  .restoreWallet(_getSeed)
                                              : null,
                                          style: kFullwidthBlueButtonStyle.copyWith(
                                            backgroundColor:
                                                WidgetStateProperty.resolveWith<Color?>(
                                              (states) => states.contains(WidgetState.disabled)
                                                  ? RealUnitColors.neutral200
                                                  : RealUnitColors.realUnitBlue,
                                            ),
                                            foregroundColor:
                                                WidgetStateProperty.resolveWith<Color?>(
                                              (states) => states.contains(WidgetState.disabled)
                                                  ? RealUnitColors.neutral400
                                                  : Colors.white,
                                            ),
                                          ),
                                          child: restoreState.isLoading
                                              ? CupertinoActivityIndicator()
                                              : Text(S.of(context).next),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

  String get _getSeed => _controllers.map((c) => c.text.trim()).join(" ");
}
