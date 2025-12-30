import 'package:flutter/material.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/dfx_country.dart';
import 'package:realunit_wallet/screens/registration/widgets/fields/registration_country_field.dart';
import 'package:realunit_wallet/screens/registration/widgets/registration_text_field.dart';

class RegistrationAddressStep extends StatelessWidget {
  final TextEditingController addressStreetCtrl;
  final TextEditingController postalCodeCtrl;
  final TextEditingController cityCtrl;
  final ValueNotifier<DfxCountry?> countryCtrl;
  final VoidCallback onPrevious;
  final Future<void> Function() onSubmit;

  RegistrationAddressStep({
    super.key,
    required this.addressStreetCtrl,
    required this.postalCodeCtrl,
    required this.cityCtrl,
    required this.countryCtrl,
    required this.onPrevious,
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
                RegistrationTextField(
                  hintText: 'Musterstrasse 12',
                  controller: addressStreetCtrl,
                  label: S.of(context).address,
                  keyboardType: TextInputType.streetAddress,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.isEmpty) return "";
                    return null;
                  },
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: [
                    Expanded(
                      flex: 2,
                      child: RegistrationTextField(
                        hintText: '8000',
                        controller: postalCodeCtrl,
                        label: S.of(context).postcode_abr,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return "";
                          return null;
                        },
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: RegistrationTextField(
                        hintText: 'Zurich',
                        controller: cityCtrl,
                        label: S.of(context).city,
                        keyboardType: TextInputType.text,
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.isEmpty) return "";
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                RegistrationCountryField(
                  label: S.of(context).country,
                  onChanged: (country) => countryCtrl.value = country,
                  validator: (value) {
                    if (value == null) return "";
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
                      child: const Text("Abschliessen"),
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
