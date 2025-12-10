import 'package:flutter/material.dart';
import 'package:realunit_wallet/screens/kyc/widgets/kyc_text_field.dart';

class KycAddressStep extends StatelessWidget {
  final TextEditingController addressStreetCtrl;
  final TextEditingController postalCodeCtrl;
  final TextEditingController cityCtrl;
  final TextEditingController countryCtrl;
  final VoidCallback onPrevious;
  final VoidCallback onSubmit;

  KycAddressStep({
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
      child: Form(
        key: _formKey,
        child: Column(
          spacing: 16,
          children: [
            KycTextField(
              hintText: 'Musterstrasse 12',
              controller: addressStreetCtrl,
              label: 'Adresse',
              keyboardType: TextInputType.streetAddress,
              validator: (value) {
                if (value == null || value.isEmpty) return "Erforderlich";
                return null;
              },
            ),
            Row(
              spacing: 10,
              children: [
                Expanded(
                  flex: 2,
                  child: KycTextField(
                    hintText: '8000',
                    controller: postalCodeCtrl,
                    label: 'PLZ',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return "Erforderlich";
                      return null;
                    },
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: KycTextField(
                    hintText: 'Zürich',
                    controller: cityCtrl,
                    label: 'Stadt',
                    keyboardType: TextInputType.text,
                    validator: (value) {
                      if (value == null || value.isEmpty) return "Erforderlich";
                      return null;
                    },
                  ),
                ),
              ],
            ),
            KycTextField(
              hintText: 'Schweiz',
              controller: countryCtrl,
              label: 'Land',
              keyboardType: TextInputType.text,
              validator: (value) {
                if (value == null || value.isEmpty) return "Erforderlich";
                return null;
              },
            ),
            FilledButton(
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  onSubmit();
                }
              },
              child: const Text("Abschliessen"),
            ),
          ],
        ),
      ),
    );
  }
}
