import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_user_type.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/cubits/registration_step/registration_step_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/widgets/fields/registration_birthday_field.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/widgets/fields/registration_country_field.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/widgets/fields/registration_phone_number_field.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/widgets/registration_dropdown_field.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/widgets/registration_text_field.dart';

class RegistrationPersonalStep extends StatelessWidget {
  final ValueNotifier<RegistrationUserType> typeCtrl;
  final TextEditingController firstNameCtrl;
  final TextEditingController lastNameCtrl;
  final ValueNotifier<String?> birthdayCtrl;
  final ValueNotifier<String?> phoneCtrl;
  final ValueNotifier<Country?> nationalityCtrl;

  RegistrationPersonalStep({
    super.key,
    required this.typeCtrl,
    required this.firstNameCtrl,
    required this.lastNameCtrl,
    required this.phoneCtrl,
    required this.nationalityCtrl,
    required this.birthdayCtrl,
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
                RegistrationDropdownField<RegistrationUserType>(
                  label: S.of(context).registerAccountType,
                  hintText: RegistrationUserType.human.toString(),
                  items: RegistrationUserType.values
                      .map((d) => DropdownMenuItem(value: d, child: Text(d.name(context))))
                      .toList(),
                  initialValue: RegistrationUserType.human,
                  onChanged: (v) {
                    if (v != null) typeCtrl.value = v;
                  },
                  validator: (v) => v == null ? '' : null,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: [
                    Expanded(
                      child: RegistrationTextField(
                        label: S.of(context).registerFirstName,
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
                        label: S.of(context).registerLastName,
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
                  label: S.of(context).registerCitizenship,
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
                          context.read<RegistrationStepCubit>().next();
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
