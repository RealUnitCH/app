import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/screens/kyc/steps/name_change/cubit/kyc_name_change_cubit.dart';
import 'package:realunit_wallet/screens/kyc/widgets/kyc_text_field.dart';

class KycNameChangePage extends StatelessWidget {
  final String url;

  const KycNameChangePage({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => KycNameChangeCubit(kycService: getIt<DfxKycService>()),
      child: KycNameChangeView(url: url),
    );
  }
}

class KycNameChangeView extends StatefulWidget {
  final String url;

  const KycNameChangeView({super.key, required this.url});

  @override
  State<KycNameChangeView> createState() => _KycNameChangeViewState();
}

class _KycNameChangeViewState extends State<KycNameChangeView> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).changeName)),
      body: BlocConsumer<KycNameChangeCubit, KycNameChangeState>(
        listener: (context, state) {
          if (state is KycNameChangeSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(S.of(context).changeSuccess)),
            );
            context.pop();
          }
        },
        builder: (context, state) {
          if (state is KycNameChangeLoading) {
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
                      KycTextField(
                        label: S.of(context).firstName,
                        hintText: 'Max',
                        controller: _firstNameCtrl,
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.isEmpty) return '';
                          return null;
                        },
                      ),
                      KycTextField(
                        label: S.of(context).lastName,
                        hintText: 'Mustermann',
                        controller: _lastNameCtrl,
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.isEmpty) return '';
                          return null;
                        },
                      ),
                      if (state is KycNameChangeFailure)
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
                                context.read<KycNameChangeCubit>().submitName(
                                      widget.url,
                                      _firstNameCtrl.text,
                                      _lastNameCtrl.text,
                                    );
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
