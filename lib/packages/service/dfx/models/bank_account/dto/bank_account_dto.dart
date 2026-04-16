class BankAccountDto {
  final int id;
  final String iban;
  final String? label;
  final bool isActive;
  final bool isDefault;

  const BankAccountDto({
    required this.id,
    required this.iban,
    this.label,
    required this.isActive,
    required this.isDefault,
  });

  factory BankAccountDto.fromJson(Map<String, dynamic> json) {
    return BankAccountDto(
      id: json['id'] as int,
      iban: json['iban'] as String,
      label: json['label'] as String?,
      isActive: json['active'] as bool,
      isDefault: json['default'] as bool,
    );
  }
}
