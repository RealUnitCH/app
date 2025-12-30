import 'package:flutter/material.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/dfx_country.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/dfx_account_type.dart';
import 'package:realunit_wallet/screens/registration/widgets/fields/registration_birthday_field.dart';
import 'package:realunit_wallet/screens/registration/widgets/fields/registration_country_field.dart';
import 'package:realunit_wallet/screens/registration/widgets/fields/registration_phone_number_field.dart';
import 'package:realunit_wallet/screens/registration/widgets/registration_dropdown_field.dart';
import 'package:realunit_wallet/screens/registration/widgets/registration_text_field.dart';

class RegistrationPersonalStep extends StatelessWidget {
  final ValueNotifier<DfxAccountType> typeCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController firstNameCtrl;
  final TextEditingController lastNameCtrl;
  final ValueNotifier<String?> birthdayCtrl;
  final ValueNotifier<String?> phoneCtrl;
  final ValueNotifier<DfxCountry?> nationalityCtrl;
  final VoidCallback onNext;

  RegistrationPersonalStep({
    super.key,
    required this.typeCtrl,
    required this.emailCtrl,
    required this.firstNameCtrl,
    required this.lastNameCtrl,
    required this.phoneCtrl,
    required this.nationalityCtrl,
    required this.birthdayCtrl,
    required this.onNext,
  });

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                RegistrationDropdownField<DfxAccountType>(
                  label: S.of(context).register_account_type,
                  hintText: DfxAccountType.human.toString(),
                  items: DfxAccountType.values
                      .map((d) => DropdownMenuItem(value: d, child: Text(d.name(context))))
                      .toList(),
                  initialValue: DfxAccountType.human,
                  onChanged: (v) {
                    if (v != null) typeCtrl.value = v;
                  },
                  validator: (v) => v == null ? '' : null,
                ),
                RegistrationTextField(
                  label: S.of(context).register_email,
                  hintText: 'max@mustermann.ch',
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  hideErrorText: false,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return S.of(context).register_email_required;
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return S.of(context).register_email_invalid;
                    }
                    return null;
                  },
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: [
                    Expanded(
                      child: RegistrationTextField(
                        label: S.of(context).register_first_name,
                        hintText: 'Max',
                        controller: firstNameCtrl,
                        // keyboardType: TextInputType.name, https://github.com/flutter/flutter/issues/67282
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.isEmpty) return '';
                          return null;
                        },
                      ),
                    ),
                    Expanded(
                      child: RegistrationTextField(
                        label: S.of(context).register_last_name,
                        hintText: 'Mustermann',
                        controller: lastNameCtrl,
                        // keyboardType: TextInputType.name, https://github.com/flutter/flutter/issues/67282
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.isEmpty) return '';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                RegistrationBirthdayField(
                  controller: birthdayCtrl,
                ),
                RegistrationPhoneNumberField(
                  controller: phoneCtrl,
                ),
                RegistrationCountryField(
                  label: S.of(context).register_citizenship,
                  onChanged: (country) => nationalityCtrl.value = country,
                  validator: (value) {
                    if (value == null) return '';
                    return null;
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          onNext();
                        }
                      },
                      child: Text(S.of(context).next),
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
}
