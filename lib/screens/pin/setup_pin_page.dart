import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/repository/settings_repository.dart';
import 'package:realunit_wallet/packages/service/biometric_service.dart';
import 'package:realunit_wallet/packages/storage/secure_storage.dart';
import 'package:realunit_wallet/screens/pin/bloc/auth/pin_auth_cubit.dart';
import 'package:realunit_wallet/screens/pin/bloc/setup_pin/setup_pin_cubit.dart';
import 'package:realunit_wallet/screens/pin/constants/pin_constants.dart';
import 'package:realunit_wallet/screens/pin/widgets/enable_biometric_bottom_sheet.dart';
import 'package:realunit_wallet/screens/pin/widgets/pin_indicator.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/number_pad.dart';

class SetupPinPage extends StatelessWidget {
  static const route = '/pin/setup';

  const SetupPinPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SetupPinCubit(
        getIt<SecureStorage>(),
        getIt<SettingsRepository>(),
        getIt<BiometricService>(),
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
      listener: (context, state) async {
        if (state.isComplete) {
          await _promptBiometricSetup(context);
          if (context.mounted) {
            getIt<PinAuthCubit>().onPinSetupComplete();
          }
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          switch (state.mode) {
                            SetupPinMode.create => S.of(context).pinCreate,
                            SetupPinMode.confirm => S.of(context).pinConfirm,
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
                            SetupPinMode.create => S.of(context).pinCreateDescription('$pinLength'),
                            SetupPinMode.confirm => S.of(context).pinConfirmDescription,
                          },
                          textAlign: TextAlign.center,
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
                            S.of(context).pinConfirmFailed,
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

  Future<void> _promptBiometricSetup(BuildContext context) async {
    final cubit = context.read<SetupPinCubit>();
    final isAvailable = await cubit.isBiometricAvailable();
    if (!isAvailable || !context.mounted) return;

    final shouldEnable = await showModalBottomSheet<bool>(
      context: context,
      builder: (_) => const EnableBiometricBottomSheet(),
    );
    if (shouldEnable == true) {
      await cubit.enableBiometrics();
    }
  }
}
