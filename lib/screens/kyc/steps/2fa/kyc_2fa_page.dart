import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/screens/kyc/cubits/kyc/kyc_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/2fa/cubits/kyc_2fa/kyc_2fa_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/2fa/cubits/kyc_2fa_verify/kyc_2fa_verify_cubit.dart';
import 'package:realunit_wallet/screens/kyc/widgets/kyc_text_field.dart';
import 'package:realunit_wallet/styles/colors.dart';

class Kyc2FaPage extends StatelessWidget {
  const Kyc2FaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => Kyc2FaCubit(
            getIt<DfxKycService>(),
          ),
        ),
        BlocProvider(
          create: (_) => Kyc2FaVerifyCubit(
            getIt<DfxKycService>(),
          ),
        ),
      ],
      child: const Kyc2FaView(),
    );
  }
}

class Kyc2FaView extends StatefulWidget {
  const Kyc2FaView({super.key});

  @override
  State<Kyc2FaView> createState() => _Kyc2FaViewState();
}

class _Kyc2FaViewState extends State<Kyc2FaView> {
  final _formKey = GlobalKey<FormState>();

  final codeCtrl = TextEditingController();

  @override
  void initState() {
    context.read<Kyc2FaCubit>().requestCode();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('2-Faktor Authentifizierung')),
      body: BlocListener<Kyc2FaVerifyCubit, Kyc2FaVerifyState>(
        listener: (context, state) {
          if (state is Kyc2FaVerifySuccess) {
            context.read<KycCubit>().checkKyc();
          }
          if (state is Kyc2FaVerifyFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Code was wrong ${state.errorMessage}'),
                backgroundColor: RealUnitColors.status.red600,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SafeArea(
            child: GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              behavior: HitTestBehavior.opaque,
              child: Form(
                key: _formKey,
                child: Column(
                  spacing: 16,
                  children: [
                    BlocBuilder<Kyc2FaCubit, Kyc2FaState>(
                      builder: (context, state) {
                        if (state is Kyc2FaSuccess) {
                          return const Text('We sent a code to your email for verification.');
                        }
                        if (state is Kyc2FaFailure) {
                          return const Text(
                            'We had a problem sending you an email with a verification code.',
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    KycTextField(
                      hintText: '123456',
                      controller: codeCtrl,
                      keyboardType: TextInputType.number,
                      hideErrorText: false,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Invalid';
                        }
                        if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                          return S.of(context).registerPhoneNumberOnlyDigits;
                        }
                        if (value.length != 6) {
                          return 'Number too short';
                        }
                        return null;
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: BlocBuilder<Kyc2FaVerifyCubit, Kyc2FaVerifyState>(
                          builder: (context, state) {
                            if (state is Kyc2FaVerifyLoading) {
                              return FilledButton.icon(
                                onPressed: null,
                                icon: SizedBox(
                                  height: 14,
                                  width: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: RealUnitColors.basic.black.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ),
                                label: Text(S.of(context).next),
                              );
                            }
                            return FilledButton(
                              onPressed: () {
                                if (_formKey.currentState?.validate() ?? false) {
                                  context.read<Kyc2FaVerifyCubit>().verifyCode(codeCtrl.text);
                                }
                              },
                              child: Text(S.of(context).next),
                            );
                          },
                        ),
                      ),
                    ),
                    BlocBuilder<Kyc2FaCubit, Kyc2FaState>(
                      builder: (context, state) {
                        final isLoading = state is Kyc2FaLoading;
                        return TextButton(
                          onPressed: isLoading
                              ? null
                              : () => context.read<Kyc2FaCubit>().requestCode(),
                          child: Text(isLoading ? 'Sending...' : 'Resend code'),
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

  @override
  void dispose() {
    codeCtrl.dispose();
    super.dispose();
  }
}
