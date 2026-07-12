import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/packages/utils/swiss_payment_text.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/cubits/registration_step/kyc_registration_step_cubit.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';
import 'package:realunit_wallet/widgets/form/country_field.dart';
import 'package:realunit_wallet/widgets/form/labeled_text_field.dart';

class KycRegistrationAddressStep extends StatelessWidget {
  final TextEditingController addressStreetCtrl;
  final TextEditingController addressNumberCtrl;
  final TextEditingController postalCodeCtrl;
  final TextEditingController cityCtrl;
  final ValueNotifier<Country?> countryCtrl;
  final Country? initialCountry;

  KycRegistrationAddressStep({
    super.key,
    required this.addressStreetCtrl,
    required this.addressNumberCtrl,
    required this.postalCodeCtrl,
    required this.cityCtrl,
    required this.countryCtrl,
    this.initialCountry,
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: [
                    Expanded(
                      flex: 2,
                      child: LabeledTextField(
                        hintText: S.of(context).streetHint,
                        controller: addressStreetCtrl,
                        label: S.of(context).street,
                        keyboardType: TextInputType.streetAddress,
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.isEmpty) return '';
                          if (!isSwissPaymentText(value)) return S.of(context).swissPaymentTextInvalid;
                          return null;
                        },
                      ),
                    ),
                    Expanded(
                      child: LabeledTextField(
                        hintText: '13',
                        controller: addressNumberCtrl,
                        label: S.of(context).number,
                        keyboardType: TextInputType.streetAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) return '';
                          if (!isSwissPaymentText(value)) return S.of(context).swissPaymentTextInvalid;
                          return null;
                        },
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
                        controller: postalCodeCtrl,
                        label: S.of(context).postcodeAbr,
                        // Postal codes are alphanumeric in many residence
                        // countries (e.g. NL "1011 AB", UK "EC1A 1BB", CA
                        // "K1A 0B1"). A number-only keyboard makes those
                        // impossible to type, while the validator + backend
                        // already accept letters and spaces.
                        keyboardType: TextInputType.text,
                        validator: (value) {
                          if (value == null || value.isEmpty) return '';
                          if (!isSwissPaymentText(value)) return S.of(context).swissPaymentTextInvalid;
                          return null;
                        },
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: LabeledTextField(
                        hintText: S.of(context).cityHint,
                        controller: cityCtrl,
                        label: S.of(context).city,
                        keyboardType: TextInputType.text,
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.isEmpty) return '';
                          if (!isSwissPaymentText(value)) return S.of(context).swissPaymentTextInvalid;
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                CountryField(
                  label: S.of(context).country,
                  purpose: CountryFieldPurpose.residence,
                  initialValue: initialCountry,
                  onChanged: (country) => countryCtrl.value = country,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: AppFilledButton(
                    onPressed: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      if (_formKey.currentState?.validate() ?? false) {
                        context.read<KycRegistrationStepCubit>().next();
                      }
                    },
                    label: S.of(context).next,
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
