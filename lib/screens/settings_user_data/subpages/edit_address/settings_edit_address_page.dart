import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/packages/utils/xfile_extension.dart';
import 'package:realunit_wallet/screens/settings_user_data/subpages/edit_address/cubit/settings_edit_address_cubit.dart';
import 'package:realunit_wallet/screens/settings_user_data/subpages/others/settings_edit_failure_page.dart';
import 'package:realunit_wallet/screens/settings_user_data/subpages/others/settings_edit_loading_page.dart';
import 'package:realunit_wallet/screens/settings_user_data/subpages/others/settings_edit_pending_page.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/form/country_field.dart';
import 'package:realunit_wallet/widgets/form/file_picker_field.dart';
import 'package:realunit_wallet/widgets/form/labeled_text_field.dart';

class SettingsEditAddressPage extends StatelessWidget {
  static const routeName = '/settings/userData/editAddress';

  const SettingsEditAddressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsEditAddressCubit(
        kycService: getIt<DfxKycService>(),
      ),
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
  Widget build(BuildContext context) {
    return BlocConsumer<SettingsEditAddressCubit, SettingsEditAddressState>(
      listener: (context, state) {
        if (state is SettingsEditAddressSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.of(context).changeSuccess),
              backgroundColor: RealUnitColors.green,
            ),
          );
          context.pop();
        }
      },
      builder: (context, state) => switch (state) {
        SettingsEditAddressLoading() => SettingsEditLoadingPage(
          title: S.of(context).changeAddress,
        ),
        SettingsEditAddressPending() => SettingsEditPendingPage(
          title: S.of(context).changeAddress,
          onRefresh: context.read<SettingsEditAddressCubit>().refresh,
        ),
        SettingsEditAddressFailure(:final message) => SettingsEditFailurePage(
          message,
          title: S.of(context).changeAddress,
          onRefresh: context.read<SettingsEditAddressCubit>().refresh,
        ),
        SettingsEditAddressReady() || SettingsEditAddressSubmitting() => Scaffold(
          appBar: AppBar(title: Text(S.of(context).changeAddress)),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isSubmitting = state is SettingsEditAddressSubmitting;
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
                              crossAxisAlignment: .stretch,
                              spacing: 16,
                              children: [
                                Row(
                                  crossAxisAlignment: .start,
                                  spacing: 10,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: LabeledTextField(
                                        hintText: 'Musterstrasse',
                                        controller: _streetCtrl,
                                        label: S.of(context).street,
                                        keyboardType: .streetAddress,
                                        textCapitalization: .words,
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
                                        label: S.of(context).number,
                                        keyboardType: .streetAddress,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  crossAxisAlignment: .start,
                                  spacing: 10,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: LabeledTextField(
                                        hintText: '8000',
                                        controller: _postalCodeCtrl,
                                        label: S.of(context).postcodeAbr,
                                        keyboardType: .number,
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
                                        keyboardType: .text,
                                        textCapitalization: .words,
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
    final country = _countryCtrl.value;
    if ((_formKey.currentState?.validate() ?? false) && _selectedFile != null && country != null) {
      final fileBase64 = await _selectedFile!.toBase64DataUri();
      if (mounted) {
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

  @override
  void dispose() {
    _streetCtrl.dispose();
    _numberCtrl.dispose();
    _postalCodeCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }
}
