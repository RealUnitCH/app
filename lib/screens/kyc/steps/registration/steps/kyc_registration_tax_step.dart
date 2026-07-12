import 'package:flutter/material.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';
import 'package:realunit_wallet/widgets/form/country_field.dart';
import 'package:realunit_wallet/widgets/form/labeled_text_field.dart';

class KycRegistrationTaxStep extends StatelessWidget {
  final ValueNotifier<Country?> taxCountryCtrl;
  final TextEditingController tinCtrl;
  final Future<void> Function() onSubmit;

  /// Pre-selects the tax-residence country — the residence country the user
  /// entered on the address step (most people are tax-resident where they
  /// live). Editable here; `null` falls back to an empty, mandatory picker.
  final Country? initialCountry;

  KycRegistrationTaxStep({
    super.key,
    required this.taxCountryCtrl,
    required this.tinCtrl,
    required this.onSubmit,
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
                // The tax-residence country defaults to the residence country
                // entered on the address step (via [initialCountry]) but stays
                // editable and mandatory: with no residence to fall back on the
                // picker is empty and CountryField's own validator blocks submit
                // until a choice is made. `swissTaxResidence` is derived from
                // this selection — a Swiss (CH) tax residence maps to Swiss-only,
                // and the TIN is collected only for a non-Swiss tax residence,
                // matching the backend contract (`swissTaxResidence` + optional
                // `countryAndTINs`).
                CountryField(
                  label: S.of(context).taxResidenceCountry,
                  purpose: CountryFieldPurpose.nationality,
                  initialValue: initialCountry,
                  onChanged: (country) => taxCountryCtrl.value = country,
                ),
                ValueListenableBuilder<Country?>(
                  valueListenable: taxCountryCtrl,
                  builder: (context, country, _) {
                    final showTin = country != null && country.symbol != 'CH';
                    if (!showTin) return const SizedBox.shrink();
                    return LabeledTextField(
                      hintText: S.of(context).tinHint,
                      controller: tinCtrl,
                      label: S.of(context).taxIdentificationNumber,
                      keyboardType: TextInputType.text,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return S.of(context).tinRequired;
                        }
                        return null;
                      },
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: AppFilledButton(
                    onPressed: () async {
                      FocusManager.instance.primaryFocus?.unfocus();
                      if (_formKey.currentState?.validate() ?? false) {
                        await onSubmit();
                      }
                    },
                    label: S.of(context).complete,
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
