import 'package:flutter/material.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_country_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/dfx_country.dart';
import 'package:realunit_wallet/screens/registration/widgets/registration_dropdown_field.dart';

class RegistrationCountryField extends StatefulWidget {
  final DfxCountry? initialCountry;
  final void Function(DfxCountry?)? onChanged;
  final String? Function(DfxCountry?)? validator;

  const RegistrationCountryField({
    super.key,
    this.initialCountry,
    this.onChanged,
    this.validator,
  });

  @override
  State<RegistrationCountryField> createState() => _RegistrationCountryFieldState();
}

class _RegistrationCountryFieldState extends State<RegistrationCountryField> {
  final DfxCountryService countryService = getIt<DfxCountryService>();
  late Future<List<DfxCountry>> _countriesFuture;

  @override
  void initState() {
    super.initState();
    _countriesFuture = _loadCountries();
  }

  Future<List<DfxCountry>> _loadCountries() async {
    final countries = await countryService.getAllCountries();

    return [countries.firstWhere((c) => c.symbol.toUpperCase() == 'CH')];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DfxCountry>>(
      future: _countriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasError) {
          return Text('Failed to load countries: ${snapshot.error}');
        }

        final countries = snapshot.data ?? [];

        return RegistrationDropdownField<DfxCountry>(
          hintText: 'Schweiz',
          label: 'Land',
          items: countries
              .map((d) => DropdownMenuItem(value: d, child: Text(d.foreignName ?? d.name)))
              .toList(),
          initialValue: widget.initialCountry,
          onChanged: widget.onChanged,
          validator: widget.validator,
        );
      },
    );
  }
}
