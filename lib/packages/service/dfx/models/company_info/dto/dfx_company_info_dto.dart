// Mirror of `CompanyInfoDto` on the API
// (`src/shared/models/company-info/dto/company-info.dto.ts`). The backend
// is the authority on the realunit-app's brand contact data — the app
// renders these fields verbatim instead of shipping them hardcoded.
class DfxCompanyInfoAddressDto {
  final String? street;
  final String? zip;
  final String? city;
  final String? country;

  const DfxCompanyInfoAddressDto({this.street, this.zip, this.city, this.country});

  factory DfxCompanyInfoAddressDto.fromJson(Map<String, dynamic> json) {
    return DfxCompanyInfoAddressDto(
      street: json['street'] as String?,
      zip: json['zip'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
    );
  }
}

class DfxCompanyInfoDto {
  final String brand;
  final String name;
  final String? phone;
  final String? email;
  final String? website;
  final DfxCompanyInfoAddressDto? address;

  const DfxCompanyInfoDto({
    required this.brand,
    required this.name,
    this.phone,
    this.email,
    this.website,
    this.address,
  });

  factory DfxCompanyInfoDto.fromJson(Map<String, dynamic> json) {
    return DfxCompanyInfoDto(
      brand: json['brand'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      address: json['address'] != null
          ? DfxCompanyInfoAddressDto.fromJson(json['address'] as Map<String, dynamic>)
          : null,
    );
  }
}
