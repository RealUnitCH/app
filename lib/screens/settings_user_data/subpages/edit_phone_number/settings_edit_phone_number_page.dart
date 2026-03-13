import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/widgets/form/phone_number_field.dart';
import 'package:realunit_wallet/screens/settings_user_data/subpages/edit_phone_number/cubit/settings_edit_phone_number_cubit.dart';

class SettingsEditPhoneNumberPage extends StatelessWidget {
  static const routeName = '/settings/userData/editPhoneNumber';

  const SettingsEditPhoneNumberPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsEditPhoneNumberCubit(
        kycService: getIt<DfxKycService>(),
      ),
      child: const SettingsEditPhoneNumberView(),
    );
  }
}

class SettingsEditPhoneNumberView extends StatefulWidget {
  const SettingsEditPhoneNumberView({super.key});

  @override
  State<SettingsEditPhoneNumberView> createState() => _SettingsEditPhoneNumberViewState();
}

class _SettingsEditPhoneNumberViewState extends State<SettingsEditPhoneNumberView> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = ValueNotifier<String?>(null);

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).changePhoneNumber)),
      body: BlocConsumer<SettingsEditPhoneNumberCubit, SettingsEditPhoneNumberState>(
        listener: (context, state) {
          if (state is PhoneChangeSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(S.of(context).changeSuccess)),
            );
            context.pop();
          }
        },
        builder: (context, state) {
          final isSubmitting = state is PhoneChangeSubmitting;

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
                      PhoneNumberField(controller: _phoneCtrl),
                      if (state is PhoneChangeFailure)
                        Text(
                          state.message,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: isSubmitting ? null : _onSubmit,
                            child: isSubmitting
                                ? const CupertinoActivityIndicator()
                                : Text(S.of(context).save),
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

  void _onSubmit() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      final phone = _phoneCtrl.value;
      if (phone != null) {
        context.read<SettingsEditPhoneNumberCubit>().submitPhone(phone);
      }
    }
  }
}
