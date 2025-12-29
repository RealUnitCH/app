import 'package:flutter/material.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_country_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/dfx_country.dart';
import 'package:realunit_wallet/screens/kyc/widgets/kyc_dropdown_field.dart';

class KycNationalityField extends StatefulWidget {
  final DfxCountry? initialCountry;
  final void Function(DfxCountry?)? onChanged;
  final String? Function(DfxCountry?)? validator;

  const KycNationalityField({
    super.key,
    this.initialCountry,
    this.onChanged,
    this.validator,
  });

  @override
  State<KycNationalityField> createState() => _KycNationalityFieldState();
}

class _KycNationalityFieldState extends State<KycNationalityField> {
  final DfxCountryService countryService = getIt<DfxCountryService>();
  late Future<List<DfxCountry>> _countriesFuture;

  @override
  void initState() {
    super.initState();
    _countriesFuture = _loadCountries();
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

        return KycDropdownField<DfxCountry>(
          hintText: 'Schweiz',
          label: 'Nationalität',
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
