import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_widget_service.dart';
import 'package:realunit_wallet/screens/registration/cubits/registration_email_verification_step/registration_email_verification_step_cubit.dart';
import 'package:realunit_wallet/screens/registration/cubits/registration_step/registration_step_cubit.dart';

class RegistrationEmailVerificationStep extends StatelessWidget {
  const RegistrationEmailVerificationStep({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RegistrationEmailVerificationStepCubit(
        dfxService: getIt<DfxWidgetService>(),
      ),
      child: const RegistrationEmailVerificationStepView(),
    );
  }
}

class RegistrationEmailVerificationStepView extends StatelessWidget {
  const RegistrationEmailVerificationStepView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<RegistrationEmailVerificationStepCubit,
        RegistrationEmailVerificationStepState>(
      listener: (context, state) {
        if (state is RegistrationEmailVerificationStepFailure) {
          print('Failure');
        }
        if (state is RegistrationEmailVerificationStepSuccess) {
          context.read<RegistrationStepCubit>().next();
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SafeArea(
            child: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Column(
            children: [
              Text('Bestätige deine Mail'),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => context
                        .read<RegistrationEmailVerificationStepCubit>()
                        .checkEmailVerification(),
                    child: Text('Ich habe die Mail bestätigt.'),
                  ),
                ),
              ),
            ],
          ),
        )),
      ),
    );
  }
}
