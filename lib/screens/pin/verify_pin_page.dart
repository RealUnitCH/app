import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/biometric_service.dart';
import 'package:realunit_wallet/packages/storage/secure_storage.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/pin/bloc/auth/pin_auth_cubit.dart';
import 'package:realunit_wallet/screens/pin/bloc/verify_pin/verify_pin_cubit.dart';
import 'package:realunit_wallet/screens/pin/widgets/forgot_pin_bottom_sheet.dart';
import 'package:realunit_wallet/screens/pin/widgets/pin_verify_scaffold.dart';
import 'package:realunit_wallet/setup/di.dart';

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
  Widget build(BuildContext context) => BlocConsumer<VerifyPinCubit, VerifyPinState>(
    listener: (context, state) {
      if (state is VerifyPinSuccess) {
        getIt<PinAuthCubit>().onPinVerified();
      }
    },
    builder: (context, state) => PinVerifyScaffold(
      pinEntryLength: state.pin.length,
      authFailed: state is VerifyPinFailure,
      onDigitAdded: context.read<VerifyPinCubit>().addDigit,
      onDeletePressed: context.read<VerifyPinCubit>().deleteDigit,
      bottom: Padding(
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
                  context.read<HomeBloc>().add(const DeleteCurrentWalletEvent());
                }
              }
            },
            child: Text(S.of(context).pinForgotten),
          ),
        ),
      ),
    ),
  );
}
