import 'package:flutter/material.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/dto/real_unit_registration_request_dto.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';
import 'package:realunit_wallet/widgets/buttons/app_text_button.dart';
import 'package:realunit_wallet/widgets/form/country_field.dart';
import 'package:realunit_wallet/widgets/form/labeled_text_field.dart';

/// Result of a completed tax-residence form. Mirrors the API contract:
/// - [swissTaxResidence] is true when any declared tax country is CH
/// - [countryAndTINs] carries every non-CH tax country with its TIN
class KycTaxResidenceSubmit {
  final bool swissTaxResidence;
  final List<CountryAndTin>? countryAndTINs;

  const KycTaxResidenceSubmit({
    required this.swissTaxResidence,
    this.countryAndTINs,
  });
}

/// One tax-residence row in the form.
class _TaxRow {
  /// When true, [country] is fixed to the address-step residence country and
  /// cannot be removed or changed — hard-wires addressCountry into the tax list.
  final bool lockedToResidence;
  Country? country;
  final TextEditingController tinCtrl;

  _TaxRow({
    required this.lockedToResidence,
    this.country,
    TextEditingController? tinCtrl,
  }) : tinCtrl = tinCtrl ?? TextEditingController();

  void dispose() => tinCtrl.dispose();
}

class KycRegistrationTaxStep extends StatefulWidget {
  /// Residence country from the address step. When non-null, it is always the
  /// first (locked) tax-residence entry so the address country is guaranteed to
  /// be among the declared tax residences. When null, the first row is a free
  /// mandatory country picker (empty-form fallback).
  final Country? residenceCountry;

  final Future<void> Function(KycTaxResidenceSubmit result) onSubmit;

  const KycRegistrationTaxStep({
    super.key,
    required this.residenceCountry,
    required this.onSubmit,
  });

  @override
  State<KycRegistrationTaxStep> createState() => _KycRegistrationTaxStepState();
}

class _KycRegistrationTaxStepState extends State<KycRegistrationTaxStep> {
  final _formKey = GlobalKey<FormState>();
  late List<_TaxRow> _rows;

  @override
  void initState() {
    super.initState();
    _rows = [_buildPrimaryRow(widget.residenceCountry)];
  }

  @override
  void didUpdateWidget(covariant KycRegistrationTaxStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep the locked primary row in sync when the address country changes
    // (user navigated back and edited residence). Additional free rows are kept.
    if (oldWidget.residenceCountry?.symbol != widget.residenceCountry?.symbol) {
      final oldPrimary = _rows.first;
      final keptAdditional = _rows.skip(1).toList();
      // Drop additional rows that collide with the new residence country.
      final residenceSymbol = widget.residenceCountry?.symbol;
      final filtered = keptAdditional.where((r) => r.country?.symbol != residenceSymbol).toList();
      for (final dropped in keptAdditional.where((r) => !filtered.contains(r))) {
        dropped.dispose();
      }
      oldPrimary.dispose();
      setState(() {
        _rows = [_buildPrimaryRow(widget.residenceCountry), ...filtered];
      });
    }
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  _TaxRow _buildPrimaryRow(Country? residence) {
    return _TaxRow(
      lockedToResidence: residence != null,
      country: residence,
    );
  }

  bool _isSwiss(Country? country) => country?.symbol == 'CH';

  Set<String> _usedSymbols({int? excludingIndex}) {
    final symbols = <String>{};
    for (var i = 0; i < _rows.length; i++) {
      if (excludingIndex != null && i == excludingIndex) continue;
      final symbol = _rows[i].country?.symbol;
      if (symbol != null) symbols.add(symbol);
    }
    return symbols;
  }

  void _addRow() {
    setState(() {
      _rows.add(_TaxRow(lockedToResidence: false));
    });
  }

  void _removeRow(int index) {
    if (index <= 0 || index >= _rows.length) return;
    setState(() {
      _rows.removeAt(index).dispose();
    });
  }

  KycTaxResidenceSubmit _buildResult() {
    final countries = _rows.map((r) => r.country).whereType<Country>().toList();
    final swissTaxResidence = countries.any((c) => c.symbol == 'CH');
    final tins = <CountryAndTin>[
      for (final row in _rows)
        if (row.country != null && row.country!.symbol != 'CH')
          CountryAndTin(
            country: row.country!.symbol,
            tin: row.tinCtrl.text.trim(),
          ),
    ];
    return KycTaxResidenceSubmit(
      swissTaxResidence: swissTaxResidence,
      countryAndTINs: tins.isEmpty ? null : tins,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
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
                // The residence (address) country is hard-wired as a tax residence:
                // it is always the first entry and, when known, cannot be removed or
                // changed. Additional tax countries may be added; each non-CH entry
                // requires a TIN. `swissTaxResidence` + `countryAndTINs` are derived
                // on submit to match the backend contract.
                for (var i = 0; i < _rows.length; i++) _buildRow(context, i),
                AppTextButton(
                  label: s.addTaxResidence,
                  icon: Icons.add,
                  onPressed: _addRow,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: AppFilledButton(
                    onPressed: () async {
                      FocusManager.instance.primaryFocus?.unfocus();
                      if (_formKey.currentState?.validate() ?? false) {
                        await widget.onSubmit(_buildResult());
                      }
                    },
                    label: s.complete,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, int index) {
    final row = _rows[index];
    final s = S.of(context);
    final showTin = row.country != null && !_isSwiss(row.country);

    return Column(
      key: ValueKey('tax-row-$index-${row.lockedToResidence}'),
      spacing: 16,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (row.lockedToResidence)
          _LockedCountryField(
            label: s.taxResidenceCountry,
            country: row.country!,
          )
        else
          CountryField(
            // Key includes used symbols so excluding already-selected countries
            // rebuilds the field when sibling rows change (no stale FormField value).
            key: ValueKey(
              'tax-free-${identityHashCode(row)}-'
              '${row.country?.symbol}-'
              '${_usedSymbols(excludingIndex: index).join(',')}',
            ),
            label: s.taxResidenceCountry,
            purpose: CountryFieldPurpose.nationality,
            initialValue: row.country,
            // Already-selected countries cannot be picked again — prevents model
            // vs FormField desync and silent payload loss on duplicate picks.
            excludeSymbols: _usedSymbols(excludingIndex: index),
            onChanged: (country) => setState(() => row.country = country),
          ),
        if (showTin)
          LabeledTextField(
            hintText: s.tinHint,
            controller: row.tinCtrl,
            label: s.taxIdentificationNumber,
            keyboardType: TextInputType.text,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return s.tinRequired;
              }
              return null;
            },
          ),
        if (!row.lockedToResidence && index > 0)
          Align(
            alignment: Alignment.centerRight,
            child: AppTextButton(
              label: s.removeTaxResidence,
              fullWidth: false,
              onPressed: () => _removeRow(index),
            ),
          ),
      ],
    );
  }
}

/// Read-only display of the residence country used as the locked tax entry.
class _LockedCountryField extends StatelessWidget {
  final String label;
  final Country country;

  const _LockedCountryField({
    required this.label,
    required this.country,
  });

  @override
  Widget build(BuildContext context) {
    // Match LabeledTextField / DropdownField label chrome (13 bold, height 18/13).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              height: 18 / 13,
            ),
          ),
        ),
        InputDecorator(
          decoration: const InputDecoration(
            filled: true,
            fillColor: RealUnitColors.neutral100,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
              borderSide: BorderSide(color: RealUnitColors.neutral300),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
              borderSide: BorderSide(color: RealUnitColors.neutral300),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 14),
          ),
          child: Text(
            country.name,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: RealUnitColors.neutral900,
                ),
          ),
        ),
      ],
    );
  }
}
