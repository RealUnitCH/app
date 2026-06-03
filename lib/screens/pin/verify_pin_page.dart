import 'dart:async';

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
import 'package:realunit_wallet/widgets/buttons/app_text_button.dart';
import 'package:realunit_wallet/widgets/number_pad.dart';

class VerifyPinParams {
  final String? description;
  final VoidCallback onAuthenticated;

  const VerifyPinParams({required this.onAuthenticated, this.description});
}

class VerifyPinPage extends StatelessWidget {
  final String? description;
  final VoidCallback onAuthenticated;
  final Widget? bottom;
  final bool enableLockout;

  /// Used to verify PIN before showing specific feature
  const VerifyPinPage({
    super.key,
    this.description,
    required this.onAuthenticated,
    this.bottom,
    this.enableLockout = true,
  });

  /// Used for initial app lock check on app start
  factory VerifyPinPage.appLock() => VerifyPinPage(
    onAuthenticated: () => getIt<PinAuthCubit>().onPinVerified(),
    bottom: const _ForgotPinButton(),
    enableLockout: true,
  );

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => VerifyPinCubit(
      getIt<SecureStorage>(),
      getIt<BiometricService>(),
      enableLockout: enableLockout,
    ),
    child: VerifyPinView(
      description: description,
      onAuthenticated: onAuthenticated,
      bottom: bottom,
    ),
  );
}

class VerifyPinView extends StatefulWidget {
  final String? description;
  final VoidCallback onAuthenticated;
  final Widget? bottom;

  const VerifyPinView({
    super.key,
    this.description,
    required this.onAuthenticated,
    this.bottom,
  });

  @override
  State<VerifyPinView> createState() => _VerifyPinViewState();
}

class _VerifyPinViewState extends State<VerifyPinView> {
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VerifyPinCubit>().checkBiometricAvailability();
    });
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<VerifyPinCubit, VerifyPinState>(
    listener: (context, state) {
      if (state is VerifyPinSuccess) {
        widget.onAuthenticated();
      } else if (state is VerifyPinTemporarilyLocked) {
        _startCountdown(state.lockedUntil);
      }
    },
    builder: (context, state) {
      final isLocked = state is VerifyPinTemporarilyLocked || state is VerifyPinLocked;

      return Scaffold(
        appBar: AppBar(),
        backgroundColor: RealUnitColors.brand700,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
                                  widget.description ?? S.of(context).pinVerifyDescription,
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
                                  wrongPin: state is VerifyPinFailure || isLocked,
                                ),
                                Visibility(
                                  visible: state is VerifyPinFailure || isLocked,
                                  maintainSize: true,
                                  maintainAnimation: true,
                                  maintainState: true,
                                  child: SizedBox(
                                    height: 40.0,
                                    child: Text(
                                      switch (state) {
                                        final VerifyPinTemporarilyLocked s =>
                                          S
                                              .of(context)
                                              .pinVerifyLockedTemporarily(
                                                _formatRemaining(s.lockedUntil),
                                              ),
                                        VerifyPinLocked _ => S.of(context).pinVerifyLocked,
                                        _ => S.of(context).pinVerifyFailed,
                                      },
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: RealUnitColors.status.red600,
                                      ),
                                      textAlign: .center,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      IgnorePointer(
                        ignoring: isLocked,
                        child: NumberPad(
                          onNumberPressed: context.read<VerifyPinCubit>().addDigit,
                          onDeletePressed: context.read<VerifyPinCubit>().deleteDigit,
                        ),
                      ),
                      if (widget.bottom != null) widget.bottom! else const SizedBox(height: 60.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown(DateTime lockedUntil) {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (DateTime.now().isAfter(lockedUntil)) {
        _countdownTimer?.cancel();
        context.read<VerifyPinCubit>().onLockExpired();
      } else {
        setState(() {});
      }
    });
  }

  String _formatRemaining(DateTime lockedUntil) {
    final remaining = lockedUntil.difference(DateTime.now());
    if (remaining.inHours >= 1) {
      final minutes = remaining.inMinutes.remainder(60);
      return '${remaining.inHours}h ${minutes}m';
    } else if (remaining.inMinutes >= 1) {
      final seconds = remaining.inSeconds.remainder(60);
      return '${remaining.inMinutes}m ${seconds}s';
    } else {
      return '${remaining.inSeconds}s';
    }
  }
}

class _ForgotPinButton extends StatelessWidget {
  const _ForgotPinButton();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: SizedBox(
      height: 52.0,
      child: AppTextButton(
        fullWidth: false,
        onPressed: () async {
          final isReset = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            builder: (_) => const ForgotPinBottomSheet(),
          );
          if (isReset == true) {
            await Future<void>.delayed(const Duration(milliseconds: 300));
            if (context.mounted) {
              await context.read<PinAuthCubit>().reset();
              if (context.mounted) {
                context.read<HomeBloc>().add(const DeleteCurrentWalletEvent());
              }
            }
          }
        },
        label: S.of(context).pinForgotten,
      ),
    ),
  );
}
