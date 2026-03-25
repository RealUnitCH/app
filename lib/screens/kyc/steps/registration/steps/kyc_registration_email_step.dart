import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';
import 'package:realunit_wallet/screens/kyc/cubits/kyc/kyc_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/cubits/registration_email_step/kyc_registration_email_step_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/subpages/kyc_registration_email_verification_page.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/form/labeled_text_field.dart';

class KycRegistrationEmailStep extends StatelessWidget {
  final TextEditingController emailCtrl;
  final Future<void> Function() onSuccess;

  const KycRegistrationEmailStep({
    super.key,
    required this.emailCtrl,
    required this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = KycRegistrationEmailStepCubit(
          getIt<RealUnitRegistrationService>(),
        );
        if (emailCtrl.text.isNotEmpty) {
          cubit.checkEmail(emailCtrl.text);
        }
        return cubit;
      },
      child: KycRegistrationEmailStepView(
        emailCtrl: emailCtrl,
        onSuccess: onSuccess,
      ),
    );
  }
}

class KycRegistrationEmailStepView extends StatelessWidget {
  final TextEditingController emailCtrl;
  final Future<void> Function() onSuccess;

  KycRegistrationEmailStepView({
    super.key,
    required this.emailCtrl,
    required this.onSuccess,
  });

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return BlocListener<KycRegistrationEmailStepCubit, KycRegistrationEmailStepState>(
      listener: (context, state) async {
        if (state is KycRegistrationEmailStepFailure) {
          final message = state.error == KycRegistrationEmailStepError.emailDoesNotMatch
              ? S.of(context).registerEmailDoesNotMatch
              : state.message;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: RealUnitColors.status.red600,
            ),
          );
        }
        if (state is KycRegistrationEmailStepSuccess) {
          if (state.status == .emailRegistered) {
            onSuccess();
          }
          if (state.status == .mergeRequested) {
            bool? isConfirmed = await Navigator.push(
              context,
              MaterialPageRoute<bool>(
                builder: (BuildContext context) => const KycRegistrationEmailVerificationPage(),
              ),
            );
            if (isConfirmed == true) {
              if (context.mounted) context.read<KycCubit>().checkKyc();
            }
          }
        }
      },
      child: BlocBuilder<KycRegistrationEmailStepCubit, KycRegistrationEmailStepState>(
        builder: (context, builderState) {
          if (builderState is! KycRegistrationEmailStepFailure && emailCtrl.text.isNotEmpty) {
            return const Center(child: CupertinoActivityIndicator());
          }
          return SingleChildScrollView(
            padding: const .symmetric(horizontal: 20),
            child: SafeArea(
              child: GestureDetector(
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      LabeledTextField(
                        label: S.of(context).email,
                        hintText: 'max@mustermann.ch',
                        controller: emailCtrl,
                        keyboardType: .emailAddress,
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
                        padding: const .symmetric(vertical: 16.0),
                        child: SizedBox(
                          width: .infinity,
                          child: BlocBuilder<KycRegistrationEmailStepCubit,
                              KycRegistrationEmailStepState>(
                            builder: (context, state) {
                              if (state is KycRegistrationEmailStepLoading) {
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
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  if (_formKey.currentState?.validate() ?? false) {
                                    context.read<KycRegistrationEmailStepCubit>().checkEmail(
                                      emailCtrl.text,
                                    );
                                  }
                                },
                                child: Text(S.of(context).next),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
