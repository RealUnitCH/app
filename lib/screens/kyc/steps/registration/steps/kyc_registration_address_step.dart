import 'package:flutter/material.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/packages/utils/swiss_payment_text.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';
import 'package:realunit_wallet/widgets/form/country_field.dart';
import 'package:realunit_wallet/widgets/form/labeled_text_field.dart';

class KycRegistrationAddressStep extends StatefulWidget {
  final TextEditingController addressStreetCtrl;
  final TextEditingController addressNumberCtrl;
  final TextEditingController postalCodeCtrl;
  final TextEditingController cityCtrl;
  final ValueNotifier<Country?> countryCtrl;

  /// Swiss-tax-residence flag the user attests. Closes BL-002: until
  /// Initiative II this value was hardcoded `true` at the page layer,
  /// disconnected from any UI. The notifier flows through the submit
  /// callback into the SignRequest so what the user ticks here is what
  /// they sign on the BitBox.
  final ValueNotifier<bool> swissTaxResidenceCtrl;

  final Future<void> Function() onSubmit;

  const KycRegistrationAddressStep({
    super.key,
    required this.addressStreetCtrl,
    required this.addressNumberCtrl,
    required this.postalCodeCtrl,
    required this.cityCtrl,
    required this.countryCtrl,
    required this.swissTaxResidenceCtrl,
    required this.onSubmit,
  });

  @override
  State<KycRegistrationAddressStep> createState() =>
      _KycRegistrationAddressStepState();
}

class _KycRegistrationAddressStepState
    extends State<KycRegistrationAddressStep> {
  final _formKey = GlobalKey<FormState>();

  /// Tracks whether the user has explicitly interacted with the
  /// checkbox. While `false`, the value follows the country selection
  /// (Switzerland → true). Once the user toggles the box manually we
  /// stop overriding so a CH-resident-who-also-files-elsewhere can
  /// untick without the country listener flipping it back.
  bool _userToggled = false;

  late final VoidCallback _countryListener;

  @override
  void initState() {
    super.initState();
    _countryListener = _onCountryChanged;
    widget.countryCtrl.addListener(_countryListener);
  }

  @override
  void dispose() {
    widget.countryCtrl.removeListener(_countryListener);
    super.dispose();
  }

  void _onCountryChanged() {
    if (_userToggled) return;
    final country = widget.countryCtrl.value;
    final shouldBeTrue = country?.symbol == 'CH';
    if (widget.swissTaxResidenceCtrl.value != shouldBeTrue) {
      widget.swissTaxResidenceCtrl.value = shouldBeTrue;
    }
  }

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
                        hintText: 'Musterstrasse',
                        controller: widget.addressStreetCtrl,
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
                        controller: widget.addressNumberCtrl,
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
                        controller: widget.postalCodeCtrl,
                        label: S.of(context).postcodeAbr,
                        keyboardType: TextInputType.number,
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
                        hintText: 'Zurich',
                        controller: widget.cityCtrl,
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
                  onChanged: (country) => widget.countryCtrl.value = country,
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: widget.swissTaxResidenceCtrl,
                  builder: (context, swissTaxResidence, _) {
                    return CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(S.of(context).swissTaxResidence),
                      subtitle: Text(
                        S.of(context).swissTaxResidenceDescription,
                      ),
                      value: swissTaxResidence,
                      onChanged: (value) {
                        _userToggled = true;
                        widget.swissTaxResidenceCtrl.value = value ?? false;
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
                        await widget.onSubmit();
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
