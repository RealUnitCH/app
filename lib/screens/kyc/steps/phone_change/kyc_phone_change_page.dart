import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/screens/kyc/steps/phone_change/cubit/kyc_phone_change_cubit.dart';
import 'package:realunit_wallet/screens/kyc/widgets/fields/kyc_phone_number_field.dart';

class KycPhoneChangePage extends StatelessWidget {
  final String url;

  const KycPhoneChangePage({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => KycPhoneChangeCubit(kycService: getIt<DfxKycService>()),
      child: KycPhoneChangeView(url: url),
    );
  }
}

class KycPhoneChangeView extends StatefulWidget {
  final String url;

  const KycPhoneChangeView({super.key, required this.url});

  @override
  State<KycPhoneChangeView> createState() => _KycPhoneChangeViewState();
}

class _KycPhoneChangeViewState extends State<KycPhoneChangeView> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = ValueNotifier<String?>(null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).changePhoneNumber)),
      body: BlocConsumer<KycPhoneChangeCubit, KycPhoneChangeState>(
        listener: (context, state) {
          if (state is KycPhoneChangeSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(S.of(context).changeSuccess)),
            );
            context.pop();
          }
        },
        builder: (context, state) {
          if (state is KycPhoneChangeLoading) {
            return const Center(child: CupertinoActivityIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: SafeArea(
              child: GestureDetector(
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                behavior: HitTestBehavior.opaque,
                child: Form(
                  key: _formKey,
                  child: Column(
                    spacing: 16,
                    children: [
                      KycPhoneNumberField(controller: _phoneCtrl),
                      if (state is KycPhoneChangeFailure)
                        Text(
                          state.message,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () {
                              FocusManager.instance.primaryFocus?.unfocus();
                              if (_formKey.currentState?.validate() ?? false) {
                                final phone = _phoneCtrl.value;
                                if (phone != null) {
                                  context.read<KycPhoneChangeCubit>().submitPhone(phone);
                                }
                              }
                            },
                            child: Text(S.of(context).save),
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
