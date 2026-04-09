import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/packages/service/biometric_service.dart';
import 'package:realunit_wallet/packages/storage/secure_storage.dart';
import 'package:realunit_wallet/screens/pin/bloc/verify_pin/verify_pin_cubit.dart';
import 'package:realunit_wallet/screens/pin/widgets/pin_verify_scaffold.dart';
import 'package:realunit_wallet/setup/di.dart';

class PinGatePage extends StatelessWidget {
  final String route;

  const PinGatePage({super.key, required this.route});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => VerifyPinCubit(
      getIt<SecureStorage>(),
      getIt<BiometricService>(),
    ),
    child: PinGateView(route: route),
  );
}

class PinGateView extends StatefulWidget {
  final String route;

  const PinGateView({super.key, required this.route});

  @override
  State<PinGateView> createState() => _PinGateViewState();
}

class _PinGateViewState extends State<PinGateView> {
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
        context.pushReplacementNamed(widget.route);
      }
    },
    builder: (context, state) => PinVerifyScaffold(
      description: 'Geben Sie Ihre PIN ein, um auf die Funktion zuzugreifen',
      pinEntryLength: state.pin.length,
      authFailed: state is VerifyPinFailure,
      onDigitAdded: context.read<VerifyPinCubit>().addDigit,
      onDeletePressed: context.read<VerifyPinCubit>().deleteDigit,
    ),
  );
}
