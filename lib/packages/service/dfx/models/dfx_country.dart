import 'package:equatable/equatable.dart';

class DfxCountry extends Equatable {
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

  const DfxCountry({
    required this.id,
    required this.symbol,
    required this.name,
    this.foreignName,
    this.locationAllowed = false,
    this.ibanAllowed = false,
    this.kycAllowed = false,
    this.kycOrganizationAllowed = false,
    this.nationalityAllowed = false,
    this.bankAllowed = false,
    this.cardAllowed = false,
    this.cryptoAllowed = false,
  });

  factory DfxCountry.fromJson(Map<String, dynamic> json) {
    return DfxCountry(
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
    );
  }

  @override
  List<Object?> get props => [id];
}
