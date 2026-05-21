class DfxCountryDto {
  final int id;
  final String symbol;
  final String name;
  final String? foreignName;
  final bool locationAllowed;
  final bool ibanAllowed;
  final bool kycAllowed;
  final bool kycOrganizationAllowed;
  final bool nationalityAllowed;
  final bool bankAllowed;
  final bool cardAllowed;
  final bool cryptoAllowed;
  // Backend-tagged sort priority for country pickers (`country.displayOrder`).
  // Lower is higher in the list. Defaults to 999 server-side for the long
  // tail and is seeded with CH=1, DE=2, IT=3, FR=4 — replacing the
  // hardcoded `priorityCountries` list the app used to ship.
  final int displayOrder;

  const DfxCountryDto({
    required this.id,
    required this.symbol,
    required this.name,
    required this.foreignName,
    required this.locationAllowed,
    required this.ibanAllowed,
    required this.kycAllowed,
    required this.kycOrganizationAllowed,
    required this.nationalityAllowed,
    required this.bankAllowed,
    required this.cardAllowed,
    required this.cryptoAllowed,
    this.displayOrder = 999,
  });

  factory DfxCountryDto.fromJson(Map<String, dynamic> json) {
    return DfxCountryDto(
      id: json['id'] as int,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      foreignName: json['foreignName'] as String?,
      locationAllowed: json['locationAllowed'] as bool,
      ibanAllowed: json['ibanAllowed'] as bool,
      kycAllowed: json['kycAllowed'] as bool,
      kycOrganizationAllowed: json['kycOrganizationAllowed'] as bool,
      nationalityAllowed: json['nationalityAllowed'] as bool,
      bankAllowed: json['bankAllowed'] as bool,
      cardAllowed: json['cardAllowed'] as bool,
      cryptoAllowed: json['cryptoAllowed'] as bool,
      displayOrder: (json['displayOrder'] as int?) ?? 999,
    );
  }
}
