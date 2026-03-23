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
            leading: switch (state.mode) {
              .create => null,
              .confirm => IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: context.read<SetupPinCubit>().reset,
              ),
            },
          ),
          backgroundColor: RealUnitColors.brand700,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        spacing: 4.0,
                        children: [
                          const Spacer(),
                          Padding(
                            padding: const .symmetric(horizontal: 20.0),
                            child: Column(
                              mainAxisSize: .min,
                              children: [
                                Column(
                                  spacing: 8.0,
                                  children: [
                                    Text(
                                      switch (state.mode) {
                                        .create => S.of(context).pinCreate,
                                        .confirm => S.of(context).pinConfirm,
                                      },
                                      textAlign: .center,
                                      style: Theme.of(context).textTheme.headlineMedium,
                                    ),
                                    Text(
                                      switch (state.mode) {
                                        .create => S.of(context).pinCreateDescription('$pinLength'),
                                        .confirm => S.of(context).pinConfirmDescription,
                                      },
                                      textAlign: .center,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: RealUnitColors.neutral500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32),
                                Column(
                                  spacing: 16.0,
                                  children: [
                                    PinIndicator(
                                      pinLength: state.currentPin.length,
                                      expectedPinLength: pinLength,
                                      wrongPin: state.mismatch,
                                    ),
                                    Visibility(
                                      visible: state.mismatch,
                                      maintainSize: true,
                                      maintainAnimation: true,
                                      maintainState: true,
                                      child: Text(
                                        S.of(context).pinConfirmFailed,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: RealUnitColors.status.red600,
                                        ),
                                        textAlign: .center,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          NumberPad(
                            onNumberPressed: (digit) =>
                                context.read<SetupPinCubit>().addDigit(digit),
                            onDeletePressed: context.read<SetupPinCubit>().deleteDigit,
                          ),
                          const SizedBox(height: 60.0),
                        ],
                      ),
                    ),
                  ),
                );
              },
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
      isScrollControlled: true,
      builder: (_) => const EnableBiometricBottomSheet(),
    );
    if (shouldEnable == true) {
      await cubit.enableBiometrics();
    }
  }
}
