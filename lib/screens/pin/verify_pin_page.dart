import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/biometric_service.dart';
import 'package:realunit_wallet/packages/storage/secure_storage.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/pin/bloc/auth/pin_auth_cubit.dart';
import 'package:realunit_wallet/screens/pin/bloc/verify_pin/verify_pin_cubit.dart';
import 'package:realunit_wallet/screens/pin/constants/pin_constants.dart';
import 'package:realunit_wallet/screens/pin/widgets/forgot_pin_bottom_sheet.dart';
import 'package:realunit_wallet/screens/pin/widgets/pin_indicator.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/number_pad.dart';

class VerifyPinPage extends StatelessWidget {
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
            return LayoutBuilder(
              builder: (context, constraint) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraint.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        spacing: 4.0,
                        children: [
                          const Spacer(),
                          Padding(
                            padding: const .symmetric(horizontal: 20.0),
                            child: Column(
                              mainAxisAlignment: .center,
                              children: [
                                Column(
                                  spacing: 8.0,
                                  children: [
                                    Text(
                                      S.of(context).pinVerify,
                                      textAlign: .center,
                                      style: Theme.of(context).textTheme.headlineMedium,
                                    ),
                                    Text(
                                      S.of(context).pinVerifyDescription,
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
                                      pinLength: state.pin.length,
                                      expectedPinLength: pinLength,
                                      wrongPin: state is VerifyPinFailure,
                                    ),
                                    Visibility(
                                      visible: state is VerifyPinFailure,
                                      maintainSize: true,
                                      maintainAnimation: true,
                                      maintainState: true,
                                      child: Text(
                                        S.of(context).pinVerifyFailed,
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
                                context.read<VerifyPinCubit>().addDigit(digit),
                            onDeletePressed: context.read<VerifyPinCubit>().deleteDigit,
                          ),
                          Padding(
                            padding: const .only(bottom: 8.0),
                            child: SizedBox(
                              height: 52.0,
                              child: TextButton(
                                onPressed: () async {
                                  final isReset = await showModalBottomSheet<bool>(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (_) => const ForgotPinBottomSheet(),
                                  );
                                  if (isReset == true) {
                                    await Future.delayed(const Duration(milliseconds: 300));
                                    if (context.mounted) {
                                      context.read<PinAuthCubit>().reset();
                                      context.read<HomeBloc>().add(
                                        const DeleteCurrentWalletEvent(),
                                      );
                                    }
                                  }
                                },
                                child: Text(S.of(context).pinForgotten),
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
    );
  }
}
