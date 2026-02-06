import 'package:flutter/material.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/screens/kyc/widgets/fields/kyc_country_field.dart';
import 'package:realunit_wallet/screens/kyc/widgets/kyc_text_field.dart';

class KycRegistrationAddressStep extends StatelessWidget {
  final TextEditingController addressStreetCtrl;
  final TextEditingController postalCodeCtrl;
  final TextEditingController cityCtrl;
  final ValueNotifier<Country?> countryCtrl;
  final Future<void> Function() onSubmit;

  KycRegistrationAddressStep({
    super.key,
    required this.addressStreetCtrl,
    required this.postalCodeCtrl,
    required this.cityCtrl,
    required this.countryCtrl,
    required this.onSubmit,
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
                KycTextField(
                  hintText: 'Musterstrasse 12',
                  controller: addressStreetCtrl,
                  label: S.of(context).address,
                  keyboardType: TextInputType.streetAddress,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.isEmpty) return '';
                    return null;
                  },
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: [
                    Expanded(
                      flex: 2,
                      child: KycTextField(
                        hintText: '8000',
                        controller: postalCodeCtrl,
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
                      child: KycTextField(
                        hintText: 'Zurich',
                        controller: cityCtrl,
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
                KycCountryField(
                  label: S.of(context).country,
                  onChanged: (country) => countryCtrl.value = country,
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
                      onPressed: () async {
                        if (_formKey.currentState?.validate() ?? false) {
                          await onSubmit();
                        }
                      },
                      child: const Text('Abschliessen'),
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
