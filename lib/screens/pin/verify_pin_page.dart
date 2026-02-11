import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/di.dart';
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
  const VerifyPinPage({super.key});

  static const route = '/pin/verify';

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => VerifyPinCubit(
      getIt<SecureStorage>(),
    ),
    child: const VerifyPinView(),
  );
}

class VerifyPinView extends StatelessWidget {
  const VerifyPinView({super.key});

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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Enter your PIN',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: RealUnitColors.realUnitBlack,
                          letterSpacing: -0.52,
                          height: 30 / 26,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Enter your PIN to unlock the wallet',
                        style: TextStyle(
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
                          'Wrong PIN. Try again.',
                          style: TextStyle(
                            fontSize: 14,
                            color: RealUnitColors.status.red600,
                          ),
                        ),
                      ],
                    ],
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
                    bool? isReset = await showModalBottomSheet(
                      context: context,
                      builder: (_) => const ForgotPinBottomSheet(),
                    );
                    if (isReset ?? false) {
                      await Future.delayed(const Duration(milliseconds: 300));
                      if (context.mounted) {
                        context.read<PinAuthCubit>().reset();
                        context.read<HomeBloc>().add(const DeleteCurrentWalletEvent());
                      }
                    }
                  },
                  child: const Text('Forgot PIN? Reset Wallet'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
