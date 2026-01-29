import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_email_status.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';
import 'package:realunit_wallet/screens/registration/cubits/registration_email_step/registration_email_step_cubit.dart';
import 'package:realunit_wallet/screens/registration/cubits/registration_step/registration_step_cubit.dart';
import 'package:realunit_wallet/screens/registration/widgets/registration_text_field.dart';
import 'package:realunit_wallet/styles/colors.dart';

class RegistrationEmailStep extends StatelessWidget {
  final TextEditingController emailCtrl;

  const RegistrationEmailStep({
    super.key,
    required this.emailCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RegistrationEmailStepCubit(
        getIt<RealUnitRegistrationService>(),
      ),
      child: RegistrationEmailStepView(
        emailCtrl: emailCtrl,
      ),
    );
  }
}

class RegistrationEmailStepView extends StatelessWidget {
  final TextEditingController emailCtrl;

  RegistrationEmailStepView({
    super.key,
    required this.emailCtrl,
  });

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return BlocListener<RegistrationEmailStepCubit, RegistrationEmailStepState>(
      listener: (context, state) {
        if (state is RegistrationEmailStepFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: RealUnitColors.status.red600,
            ),
          );
        }
        if (state is RegistrationEmailStepSuccess) {
          if (state.status == RegistrationEmailStatus.emailRegistered) {
            context.read<RegistrationStepCubit>().checkForEmailVerification(required: false);
            context.read<RegistrationStepCubit>().next();
          }
          if (state.status == RegistrationEmailStatus.mergeRequested) {
            context.read<RegistrationStepCubit>().checkForEmailVerification(required: true);
            context.read<RegistrationStepCubit>().next();
          }
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SafeArea(
            child: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Form(
              key: _formKey,
              child: Column(
                children: [
                  RegistrationTextField(
                    label: S.of(context).registerEmail,
                    hintText: 'max@mustermann.ch',
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    hideErrorText: false,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return S.of(context).registerEmailRequired;
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return S.of(context).registerEmailInvalid;
                      }
                      return null;
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: BlocBuilder<RegistrationEmailStepCubit, RegistrationEmailStepState>(
                        builder: (context, state) {
                          if (state is RegistrationEmailStepLoading) {
                            return FilledButton.icon(
                              onPressed: null,
                              icon: SizedBox(
                                height: 14,
                                width: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: RealUnitColors.basic.black.withValues(alpha: 0.5),
                                ),
                              ),
                              label: Text(S.of(context).next),
                            );
                          }
                          return FilledButton(
                            onPressed: () {
                              if (_formKey.currentState?.validate() ?? false) {
                                context
                                    .read<RegistrationEmailStepCubit>()
                                    .checkEmail(emailCtrl.text);
                              }
                            },
                            child: Text(S.of(context).next),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              )),
        )),
      ),
    );
  }
}
