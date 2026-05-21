import 'package:flutter/material.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_country_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/widgets/form/dropdown_field.dart';

class CountryField extends StatefulWidget {
  final String label;
  final void Function(Country?)? onChanged;
  final String? Function(Country?)? validator;

  const CountryField({
    super.key,
    required this.label,
    this.onChanged,
    this.validator,
  });

  @override
  State<CountryField> createState() => _CountryFieldState();
}

class _CountryFieldState extends State<CountryField> {
  final DfxCountryService countryService = getIt<DfxCountryService>();
  late Future<List<Country>> _countriesFuture;
  bool _hasPreloaded = false;

  @override
  void initState() {
    super.initState();
    _countriesFuture = _loadCountries();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Country>>(
      future: _countriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasError) {
          return Text('Failed to load countries: ${snapshot.error}');
        }

        final countries = snapshot.data ?? [];
        final initialCountry = countries.isNotEmpty ? countries.first : null;
        _preloadCountry(initialCountry);

        return DropdownField<Country>(
          hintText: 'Schweiz',
          label: widget.label,
          items: countries.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
          initialValue: initialCountry,
          onChanged: widget.onChanged,
          validator: widget.validator,
        );
      },
    );
  }

  Future<List<Country>> _loadCountries() async {
    // The API tags each country with `displayOrder` (lower is higher in the
    // picker). The backend already sorts by `displayOrder` then `name`, so
    // the list arrives in the right order — no local priority list needed.
    return countryService.getAllCountries();
  }

  void _preloadCountry(Country? initialCountry) {
    if (!_hasPreloaded && initialCountry != null) {
      _hasPreloaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onChanged?.call(initialCountry);
      });
    }
  }
}
