import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/packages/repository/settings_repository.dart';
import 'package:realunit_wallet/packages/storage/secure_storage.dart';
import 'package:realunit_wallet/screens/pin/bloc/auth/pin_auth_cubit.dart';
import 'package:realunit_wallet/screens/pin/bloc/setup_pin/setup_pin_cubit.dart';
import 'package:realunit_wallet/screens/pin/constants/pin_constants.dart';
import 'package:realunit_wallet/screens/pin/widgets/pin_indicator.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/number_pad.dart';

class SetupPinPage extends StatelessWidget {
  const SetupPinPage({super.key});

  static const route = '/pin/setup';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SetupPinCubit(
        getIt<SecureStorage>(),
        getIt<SettingsRepository>(),
      ),
      child: const SetupPinView(),
    );
  }
}

class SetupPinView extends StatelessWidget {
  const SetupPinView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SetupPinCubit, SetupPinState>(
      listener: (context, state) {
        if (state.isComplete) {
          getIt<PinAuthCubit>().onPinSetupComplete();
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            leading: state.mode == SetupPinMode.confirm
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: switch (state.mode) {
                      SetupPinMode.create => null,
                      SetupPinMode.confirm => () => context.read<SetupPinCubit>().reset(),
                    },
                  )
                : null,
          ),
          backgroundColor: RealUnitColors.brand700,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        switch (state.mode) {
                          SetupPinMode.create => 'Create your PIN',
                          SetupPinMode.confirm => 'Confirm your PIN',
                        },
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
                        switch (state.mode) {
                          SetupPinMode.create => 'Enter a 4-digit PIN to secure your wallet',
                          SetupPinMode.confirm => 'Re-enter your PIN to confirm',
                        },
                        style: const TextStyle(
                          fontSize: 14,
                          color: RealUnitColors.neutral500,
                          height: 18 / 14,
                        ),
                      ),
                      const SizedBox(height: 40),
                      PinIndicator(
                        pinLength: state.currentPin.length,
                        expectedPinLength: pinLength,
                        wrongPin: state.mismatch,
                      ),
                      if (state.mismatch) ...[
                        const SizedBox(height: 16),
                        Text(
                          'PINs do not match. Try again.',
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
                    onNumberPressed: (digit) => context.read<SetupPinCubit>().addDigit(digit),
                    onDeletePressed: () => context.read<SetupPinCubit>().deleteDigit(),
                  ),
                ),
                const SizedBox(height: 40.0),
              ],
            ),
          ),
        );
      },
    );
  }
}
