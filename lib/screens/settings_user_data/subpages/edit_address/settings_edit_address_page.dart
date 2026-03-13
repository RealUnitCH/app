import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/widgets/form/country_field.dart';
import 'package:realunit_wallet/widgets/form/file_picker_field.dart';
import 'package:realunit_wallet/widgets/form/labeled_text_field.dart';
import 'package:realunit_wallet/screens/settings_user_data/subpages/edit_address/cubit/settings_edit_address_cubit.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/text_substring_highlighting.dart';

class SettingsEditAddressPage extends StatelessWidget {
  static const routeName = '/settings/userData/editAddress';

  const SettingsEditAddressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SettingsEditAddressCubit(kycService: getIt<DfxKycService>())..startStep(),
      child: const SettingsEditAddressView(),
    );
  }
}

class SettingsEditAddressView extends StatefulWidget {
  const SettingsEditAddressView({super.key});

  @override
  State<SettingsEditAddressView> createState() => _SettingsEditAddressViewState();
}

class _SettingsEditAddressViewState extends State<SettingsEditAddressView> {
  final _formKey = GlobalKey<FormState>();
  final _streetCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _postalCodeCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _countryCtrl = ValueNotifier<Country?>(null);
  XFile? _selectedFile;
  bool _fileValidationTriggered = false;

  @override
  void dispose() {
    _streetCtrl.dispose();
    _numberCtrl.dispose();
    _postalCodeCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).changeAddress)),
      body: BlocConsumer<SettingsEditAddressCubit, SettingsEditAddressState>(
        listener: (context, state) {
          if (state is AddressChangeSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(S.of(context).changeSuccess)),
            );
            context.pop();
          }
        },
        builder: (context, state) => switch (state) {
          AddressChangeLoading() => const Center(child: CupertinoActivityIndicator()),
          AddressChangePending() => _buildPendingView(context),
          AddressChangeFailure(:final message) => _buildFailureView(context, message),
          AddressChangeReady() || AddressChangeSubmitting() => _buildFormView(context, state),
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
              text: S.of(context).kycPendingDescription('ADDRESSCHANGE'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: RealUnitColors.neutral500,
                fontSize: 14,
                height: 18 / 14,
              ),
              highlightedText: 'ADDRESSCHANGE',
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
                  onPressed: () => context.read<SettingsEditAddressCubit>().refresh(),
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
                  onPressed: () => context.read<SettingsEditAddressCubit>().refresh(),
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

  Widget _buildFormView(BuildContext context, SettingsEditAddressState state) {
    final isSubmitting = state is AddressChangeSubmitting;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SafeArea(
        child: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          behavior: HitTestBehavior.opaque,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: [
                    Expanded(
                      flex: 2,
                      child: LabeledTextField(
                        hintText: 'Musterstrasse',
                        controller: _streetCtrl,
                        label: S.of(context).street,
                        keyboardType: TextInputType.streetAddress,
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.isEmpty) return '';
                          return null;
                        },
                      ),
                    ),
                    Expanded(
                      child: LabeledTextField(
                        hintText: '13',
                        controller: _numberCtrl,
                        label: S.of(context).houseNumber,
                        keyboardType: TextInputType.streetAddress,
                      ),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: [
                    Expanded(
                      flex: 2,
                      child: LabeledTextField(
                        hintText: '8000',
                        controller: _postalCodeCtrl,
                        label: S.of(context).postcodeAbr,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return '';
                          return null;
                        },
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: LabeledTextField(
                        hintText: 'Zurich',
                        controller: _cityCtrl,
                        label: S.of(context).city,
                        keyboardType: TextInputType.text,
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.isEmpty) return '';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                CountryField(
                  label: S.of(context).country,
                  onChanged: (country) => _countryCtrl.value = country,
                  validator: (value) {
                    if (value == null) return '';
                    return null;
                  },
                ),
                FilePickerField(
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
    final country = _countryCtrl.value;
    if ((_formKey.currentState?.validate() ?? false) && _selectedFile != null && country != null) {
      final fileBase64 = await FilePickerField.toBase64DataUri(_selectedFile);
      if (fileBase64 != null && mounted) {
        context.read<SettingsEditAddressCubit>().submitAddress(
          street: _streetCtrl.text,
          houseNumber: _numberCtrl.text,
          zip: _postalCodeCtrl.text,
          city: _cityCtrl.text,
          countryId: country.id,
          fileBase64: fileBase64,
          fileName: _selectedFile!.name,
        );
      }
    }
  }
}
