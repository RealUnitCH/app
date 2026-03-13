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
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/text_substring_highlighting.dart';

class SettingsEditNamePage extends StatelessWidget {
  static const routeName = '/settings/userData/editName';

  const SettingsEditNamePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsEditNameCubit(kycService: getIt<DfxKycService>())..startStep(),
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
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).changeName)),
      body: BlocConsumer<SettingsEditNameCubit, SettingsEditNameState>(
        listener: (context, state) {
          if (state is NameChangeSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(S.of(context).changeSuccess)),
            );
            context.pop();
          }
        },
        builder: (context, state) => switch (state) {
          NameChangeLoading() => const Center(child: CupertinoActivityIndicator()),
          NameChangePending() => _buildPendingView(context),
          NameChangeFailure(:final message) => _buildFailureView(context, message),
          NameChangeReady() || NameChangeSubmitting() => _buildFormView(context, state),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }

  Widget _buildPendingView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: SafeArea(
        child: Column(
          spacing: 8.0,
          children: [
            const Spacer(),
            Text(
              S.of(context).kycPending,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                height: 30 / 26,
                letterSpacing: -0.52,
              ),
            ),
            TextSubstringHighlighting(
              text: S.of(context).kycPendingDescription('NAMECHANGE'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: RealUnitColors.neutral500,
                fontSize: 14,
                height: 18 / 14,
              ),
              highlightedText: 'NAMECHANGE',
              highlightedStyle: const TextStyle(
                color: RealUnitColors.neutral500,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                height: 18 / 14,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.read<SettingsEditNameCubit>().refresh(),
                  child: Text(S.of(context).refresh),
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildFailureView(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: SafeArea(
        child: Column(
          spacing: 8.0,
          children: [
            const Spacer(),
            Text(
              S.of(context).kycFailure,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                height: 30 / 26,
                letterSpacing: -0.52,
              ),
            ),
            Text(
              S.of(context).kycFailureDescription(message),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: RealUnitColors.neutral500,
                fontSize: 14,
                height: 18 / 14,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.read<SettingsEditNameCubit>().refresh(),
                  child: Text(S.of(context).refresh),
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormView(BuildContext context, SettingsEditNameState state) {
    final isSubmitting = state is NameChangeSubmitting;

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
                KycFilePickerField(
                  label: S.of(context).proofDocument,
                  selectedFile: _selectedFile,
                  onFileSelected: (file) => setState(() => _selectedFile = file),
                  validator: () {
                    if (_fileValidationTriggered && _selectedFile == null) return '';
                    return null;
                  },
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
