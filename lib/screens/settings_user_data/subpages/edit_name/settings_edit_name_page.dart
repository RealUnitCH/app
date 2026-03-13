import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/screens/kyc/widgets/fields/kyc_file_picker_field.dart';
import 'package:realunit_wallet/screens/kyc/widgets/kyc_text_field.dart';
import 'package:realunit_wallet/screens/settings_user_data/subpages/edit_name/cubit/settings_edit_name_cubit.dart';
import 'package:realunit_wallet/screens/settings_user_data/subpages/settings_edit_failure_page.dart';
import 'package:realunit_wallet/screens/settings_user_data/subpages/settings_edit_pending_page.dart';

class SettingsEditNamePage extends StatelessWidget {
  static const routeName = '/settings/userData/editName';

  const SettingsEditNamePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsEditNameCubit(
        kycService: getIt<DfxKycService>(),
      ),
      child: const SettingsEditNameView(),
    );
  }
}

class SettingsEditNameView extends StatefulWidget {
  const SettingsEditNameView({super.key});

  @override
  State<SettingsEditNameView> createState() => _SettingsEditNameViewState();
}

class _SettingsEditNameViewState extends State<SettingsEditNameView> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  XFile? _selectedFile;
  bool _fileValidationTriggered = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SettingsEditNameCubit, SettingsEditNameState>(
      listener: (context, state) {
        if (state is SettingsEditNameSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).changeSuccess)),
          );
          context.pop();
        }
      },
      builder: (context, state) => switch (state) {
        SettingsEditNameLoading() => Scaffold(
          appBar: AppBar(title: Text(S.of(context).changeName)),
          body: const Center(child: CupertinoActivityIndicator()),
        ),
        SettingsEditNamePending() => SettingsEditPendingPage(
          title: S.of(context).changeName,
          onRefresh: context.read<SettingsEditNameCubit>().refresh,
        ),
        SettingsEditNameFailure(:final message) => SettingsEditFailurePage(
          message,
          title: S.of(context).changeName,
          onRefresh: context.read<SettingsEditNameCubit>().refresh,
        ),
        SettingsEditNameReady() || SettingsEditNameSubmitting() => Scaffold(
          appBar: AppBar(title: Text(S.of(context).changeName)),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isSubmitting = state is SettingsEditNameSubmitting;
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: SafeArea(
                      child: Padding(
                        padding: const .symmetric(horizontal: 20),
                        child: GestureDetector(
                          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                          behavior: .opaque,
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
                                KycFilePickerField(
                                  label: S.of(context).proofDocument,
                                  selectedFile: _selectedFile,
                                  onFileSelected: (file) => setState(() => _selectedFile = file),
                                  validator: () {
                                    if (_fileValidationTriggered && _selectedFile == null) {
                                      return '';
                                    }
                                    return null;
                                  },
                                ),
                                const Spacer(),
                                Padding(
                                  padding: const .symmetric(vertical: 16.0),
                                  child: SizedBox(
                                    width: .infinity,
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
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }

  Future<void> _onSubmit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _fileValidationTriggered = true);
    if ((_formKey.currentState?.validate() ?? false) && _selectedFile != null) {
      final fileBase64 = await KycFilePickerField.toBase64DataUri(_selectedFile);
      if (fileBase64 != null && mounted) {
        context.read<SettingsEditNameCubit>().submitName(
          firstName: _firstNameCtrl.text,
          lastName: _lastNameCtrl.text,
          fileBase64: fileBase64,
          fileName: _selectedFile!.name,
        );
      }
    }
  }
}
