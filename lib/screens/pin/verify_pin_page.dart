import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/biometric_service.dart';
import 'package:realunit_wallet/packages/storage/secure_storage.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/pin/bloc/auth/pin_auth_cubit.dart';
import 'package:realunit_wallet/screens/pin/bloc/verify_pin/verify_pin_cubit.dart';
import 'package:realunit_wallet/screens/pin/constants/pin_constants.dart';
import 'package:realunit_wallet/screens/pin/widgets/forgot_pin_bottom_sheet.dart';
import 'package:realunit_wallet/screens/pin/widgets/pin_indicator.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/number_pad.dart';

class VerifyPinPage extends StatelessWidget {
  static const route = '/pin/verify';

  const VerifyPinPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => VerifyPinCubit(
      getIt<SecureStorage>(),
      getIt<BiometricService>(),
    ),
    child: const VerifyPinView(),
  );
}

class VerifyPinView extends StatefulWidget {
  const VerifyPinView({super.key});

  @override
  State<VerifyPinView> createState() => _VerifyPinViewState();
}

class _VerifyPinViewState extends State<VerifyPinView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VerifyPinCubit>().checkBiometricAvailability();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      backgroundColor: RealUnitColors.brand700,
      body: SafeArea(
        child: BlocConsumer<VerifyPinCubit, VerifyPinState>(
          listener: (context, state) {
            if (state is VerifyPinSuccess) {
              getIt<PinAuthCubit>().onPinVerified();
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          S.of(context).pinVerify,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: RealUnitColors.realUnitBlack,
                            letterSpacing: -0.52,
                            height: 30 / 26,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          S.of(context).pinVerifyDescription,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: RealUnitColors.neutral500,
                            height: 18 / 14,
                          ),
                        ),
                        const SizedBox(height: 40),
                        PinIndicator(
                          pinLength: state.pin.length,
                          expectedPinLength: pinLength,
                          wrongPin: state is VerifyPinFailure,
                        ),
                        if (state is VerifyPinFailure) ...[
                          const SizedBox(height: 16),
                          Text(
                            S.of(context).pinVerifyFailed,
                            style: TextStyle(
                              fontSize: 14,
                              color: RealUnitColors.status.red600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: NumberPad(
                    onNumberPressed: (digit) => context.read<VerifyPinCubit>().addDigit(digit),
                    onDeletePressed: () => context.read<VerifyPinCubit>().deleteDigit(),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    bool isReset = await showModalBottomSheet(
                      context: context,
                      builder: (_) => const ForgotPinBottomSheet(),
                    );
                    if (isReset) {
                      await Future.delayed(const Duration(milliseconds: 300));
                      if (context.mounted) {
                        context.read<PinAuthCubit>().reset();
                        context.read<HomeBloc>().add(const DeleteCurrentWalletEvent());
                      }
                    }
                  },
                  child: Text(S.of(context).pinForgotten),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
