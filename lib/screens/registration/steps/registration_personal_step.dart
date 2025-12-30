import 'package:flutter/material.dart';
import 'package:realunit_wallet/packages/service/dfx/models/dfx_country.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/dfx_user_type.dart';
import 'package:realunit_wallet/screens/registration/widgets/fields/registration_birthday_field.dart';
import 'package:realunit_wallet/screens/registration/widgets/fields/registration_country_field.dart';
import 'package:realunit_wallet/screens/registration/widgets/fields/registration_phone_number_field.dart';
import 'package:realunit_wallet/screens/registration/widgets/registration_dropdown_field.dart';
import 'package:realunit_wallet/screens/registration/widgets/registration_text_field.dart';

class RegistrationPersonalStep extends StatelessWidget {
  final ValueNotifier<DfxUserType> typeCtrl;
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
        child: Form(
          key: _formKey,
          child: Column(
            spacing: 16,
            children: [
              RegistrationDropdownField<DfxUserType>(
                label: 'Kontotyp',
                hintText: DfxUserType.human.toString(),
                items: DfxUserType.values
                    .map((d) => DropdownMenuItem(value: d, child: Text(d.name)))
                    .toList(),
                initialValue: DfxUserType.human,
                onChanged: (v) {
                  if (v != null) typeCtrl.value = v;
                },
                validator: (v) => v == null ? "Erforderlich" : null,
              ),
              RegistrationTextField(
                label: 'E-Mail',
                hintText: 'E-Mail',
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return "E-Mail ist erforderlich";
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return "E-Mail ist ungültig";
                  return null;
                },
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  Expanded(
                    child: RegistrationTextField(
                      label: 'Vorname',
                      hintText: 'Max',
                      controller: firstNameCtrl,
                      keyboardType: TextInputType.name,
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Erforderlich";
                        return null;
                      },
                    ),
                  ),
                  Expanded(
                    child: RegistrationTextField(
                      label: 'Nachname',
                      hintText: 'Mustermann',
                      controller: lastNameCtrl,
                      keyboardType: TextInputType.name,
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Erforderlich";
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
                label: 'Nationalität',
                onChanged: (country) => nationalityCtrl.value = country,
                validator: (value) {
                  if (value == null) return "Nationalität ist erforderlich";
                  return null;
                },
              ),
              FilledButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    onNext();
                  }
                },
                child: const Text("Weiter"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
