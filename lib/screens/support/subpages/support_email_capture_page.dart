import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';
import 'package:realunit_wallet/screens/support/cubits/support_email_capture/support_email_capture_cubit.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';
import 'package:realunit_wallet/widgets/form/labeled_text_field.dart';

/// Stand-alone email-capture step that gates ticket creation when the
/// user record on `/v2/user` has no `mail`. Pops back to `SupportPage`
/// with `true` on a successful registerEmail call so the caller can
/// chain the original `SupportRoutes.createTicket` push.
///
/// Intentionally NOT wired into `KycCubit`: this page is reachable from
/// pre-signin contexts and must not fire KYC-state transitions. Only the
/// minimal `RealUnitRegistrationService.registerEmail` call is performed.
class SupportEmailCapturePage extends StatelessWidget {
  const SupportEmailCapturePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SupportEmailCaptureCubit(
        getIt<RealUnitRegistrationService>(),
      ),
      child: const SupportEmailCaptureView(),
    );
  }
}

class SupportEmailCaptureView extends StatelessWidget {
  const SupportEmailCaptureView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).supportEmailCaptureTitle),
      ),
      body: const SupportEmailCaptureForm(),
    );
  }
}

class SupportEmailCaptureForm extends StatefulWidget {
  const SupportEmailCaptureForm({super.key});

  @override
  State<SupportEmailCaptureForm> createState() => _SupportEmailCaptureFormState();
}

class _SupportEmailCaptureFormState extends State<SupportEmailCaptureForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SupportEmailCaptureCubit, SupportEmailCaptureState>(
      listener: (context, state) {
        if (state is SupportEmailCaptureSuccess) {
          // Pop with `true` so the SupportPage listener knows to chain
          // pushNamed(SupportRoutes.createTicket).
          context.pop(true);
        }
        if (state is SupportEmailCaptureFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: RealUnitColors.status.red600,
            ),
          );
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: SafeArea(
          child: GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Text(
                      S.of(context).supportEmailCaptureDescription,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  LabeledTextField(
                    label: S.of(context).email,
                    hintText: 'max@mustermann.ch',
                    controller: _emailCtrl,
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
                    child: BlocBuilder<SupportEmailCaptureCubit, SupportEmailCaptureState>(
                      builder: (context, state) {
                        return AppFilledButton(
                          state: state is SupportEmailCaptureSubmitting
                              ? FilledButtonState.loading
                              : FilledButtonState.idle,
                          onPressed: () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            if (_formKey.currentState?.validate() ?? false) {
                              context.read<SupportEmailCaptureCubit>().submit(
                                _emailCtrl.text.trim(),
                              );
                            }
                          },
                          label: S.of(context).supportEmailCaptureContinue,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
