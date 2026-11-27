import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';
import 'package:realunit_wallet/screens/kyc/steps/email/cubits/email_code/kyc_email_code_cubit.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';
import 'package:realunit_wallet/widgets/buttons/app_text_button.dart';
import 'package:realunit_wallet/widgets/form/labeled_text_field.dart';
import 'package:realunit_wallet/widgets/scrollable_actions_layout.dart';

/// Code entry for an address the API has not stored yet
/// (register/email returned `verification_code_sent`). Pops with the final
/// `RegistrationEmailStatus` once the email step is finished.
class KycEmailCodePage extends StatelessWidget {
  final String email;

  const KycEmailCodePage({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => KycEmailCodeCubit(
        getIt<RealUnitRegistrationService>(),
        email: email,
      ),
      child: const KycEmailCodeView(),
    );
  }
}

class KycEmailCodeView extends StatefulWidget {
  const KycEmailCodeView({super.key});

  @override
  State<KycEmailCodeView> createState() => _KycEmailCodeViewState();
}

class _KycEmailCodeViewState extends State<KycEmailCodeView> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<KycEmailCodeCubit, KycEmailCodeState>(
      listener: (context, state) {
        // The user may leave while a request is in flight. Once this route is
        // no longer current (its exit animation still runs), a late result
        // must not pop or show anything: a pop would remove the route below.
        final route = ModalRoute.of(context);
        if (route != null && !route.isCurrent) return;
        if (state is KycEmailCodeCompleted) {
          Navigator.of(context).pop(state.status);
          return;
        }
        if (state is KycEmailCodeResent) {
          _codeCtrl.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).registerEmailCodeResent)),
          );
          return;
        }
        if (state is KycEmailCodeFailure) {
          final message = switch (state.error) {
            KycEmailCodeError.invalidCode => S.of(context).registerEmailCodeInvalid,
            KycEmailCodeError.unknown => S.of(context).registerEmailCodeFailed,
          };
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: RealUnitColors.status.red600,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(S.of(context).registerEmailCode)),
        body: Padding(
          padding: const .symmetric(horizontal: 20),
          child: SafeArea(
            child: GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              behavior: .opaque,
              child: Form(
                key: _formKey,
                child: ScrollableActionsLayout(
                  body: Column(
                    crossAxisAlignment: .start,
                    spacing: 16,
                    children: [
                      Padding(
                        padding: const .only(top: 16),
                        child: Text(
                          S.of(context).registerEmailCodeTitle,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      Text(
                        S.of(context).registerEmailCodeDescription(
                          context.read<KycEmailCodeCubit>().email,
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: RealUnitColors.neutral500,
                        ),
                      ),
                      LabeledTextField(
                        label: S.of(context).registerEmailCodeLabel,
                        hintText: '123456',
                        controller: _codeCtrl,
                        keyboardType: TextInputType.number,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        hideErrorText: false,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return S.of(context).twoFaCodeRequired;
                          }
                          if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                            return S.of(context).registerPhoneNumberOnlyDigits;
                          }
                          if (value.length != 6) {
                            return S.of(context).twoFaCodeTooShort;
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  actionsSpacing: 4,
                  actions: [
                    BlocBuilder<KycEmailCodeCubit, KycEmailCodeState>(
                      builder: (context, state) => AppFilledButton(
                        state: state is KycEmailCodeVerifying ? .loading : .idle,
                        onPressed: state is KycEmailCodeResending
                            ? null
                            : () {
                                FocusManager.instance.primaryFocus?.unfocus();
                                if (_formKey.currentState?.validate() ?? false) {
                                  context.read<KycEmailCodeCubit>().verify(
                                    _codeCtrl.text.trim(),
                                  );
                                }
                              },
                        label: S.of(context).next,
                      ),
                    ),
                    BlocBuilder<KycEmailCodeCubit, KycEmailCodeState>(
                      builder: (context, state) {
                        final isResending = state is KycEmailCodeResending;
                        return AppTextButton(
                          fullWidth: false,
                          onPressed: state is KycEmailCodeVerifying || isResending
                              ? null
                              : () => context.read<KycEmailCodeCubit>().resend(),
                          label: isResending
                              ? '${S.of(context).sending}...'
                              : S.of(context).twoFaResendCode,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
