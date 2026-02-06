import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_user_type.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/cubits/registration_step/kyc_registration_step_cubit.dart';
import 'package:realunit_wallet/screens/kyc/widgets/fields/kyc_birthday_field.dart';
import 'package:realunit_wallet/screens/kyc/widgets/fields/kyc_country_field.dart';
import 'package:realunit_wallet/screens/kyc/widgets/fields/kyc_phone_number_field.dart';
import 'package:realunit_wallet/screens/kyc/widgets/kyc_dropdown_field.dart';
import 'package:realunit_wallet/screens/kyc/widgets/kyc_text_field.dart';

class KycRegistrationPersonalStep extends StatelessWidget {
  final ValueNotifier<RegistrationUserType> typeCtrl;
  final TextEditingController firstNameCtrl;
  final TextEditingController lastNameCtrl;
  final ValueNotifier<String?> birthdayCtrl;
  final ValueNotifier<String?> phoneCtrl;
  final ValueNotifier<Country?> nationalityCtrl;

  KycRegistrationPersonalStep({
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
                KycDropdownField<RegistrationUserType>(
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
                      child: KycTextField(
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
                      child: KycTextField(
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
                KycBirthdayField(
                  controller: birthdayCtrl,
                ),
                KycPhoneNumberField(
                  controller: phoneCtrl,
                ),
                KycCountryField(
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
                          context.read<KycRegistrationStepCubit>().next();
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
