import 'package:flutter/material.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_country_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/dfx_country.dart';
import 'package:realunit_wallet/screens/registration/widgets/registration_dropdown_field.dart';

class RegistrationCountryField extends StatefulWidget {
  final String label;
  final void Function(DfxCountry?)? onChanged;
  final String? Function(DfxCountry?)? validator;

  const RegistrationCountryField({
    super.key,
    required this.label,
    this.onChanged,
    this.validator,
  });

  @override
  State<RegistrationCountryField> createState() => _RegistrationCountryFieldState();
}

class _RegistrationCountryFieldState extends State<RegistrationCountryField> {
  final DfxCountryService countryService = getIt<DfxCountryService>();
  late Future<List<DfxCountry>> _countriesFuture;
  bool _hasPreloaded = false;

  @override
  void initState() {
    super.initState();
    _countriesFuture = _loadCountries();
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
        final initialCountry = countries.isNotEmpty ? countries.first : null;
        _preloadCountry(initialCountry);

        return RegistrationDropdownField<DfxCountry>(
          hintText: 'Schweiz',
          label: widget.label,
          items: countries.map((d) => DropdownMenuItem(value: d, child: Text(d.name))).toList(),
          initialValue: initialCountry,
          onChanged: widget.onChanged,
          validator: widget.validator,
        );
      },
    );
  }

  Future<List<DfxCountry>> _loadCountries() async {
    final countries = await countryService.getAllCountries();

    final priority = ['CH', 'DE', 'IT', 'FR'];

    countries.sort((a, b) {
      final aIndex = priority.indexOf(a.symbol.toUpperCase());
      final bIndex = priority.indexOf(b.symbol.toUpperCase());

      if (aIndex != -1 && bIndex != -1) {
        return aIndex.compareTo(bIndex);
      }

      if (aIndex != -1) return -1;
      if (bIndex != -1) return 1;

      return a.name.compareTo(b.name);
    });

    return countries;
  }

  void _preloadCountry(DfxCountry? initialCountry) {
    if (!_hasPreloaded && initialCountry != null) {
      _hasPreloaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onChanged?.call(initialCountry);
      });
    }
  }
}
