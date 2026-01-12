class BankAccount {
  final String? name;
  final String iban;

  BankAccount({
    this.name,
    required this.iban,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'iban': iban,
      };

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      name: json['name'] as String?,
      iban: json['iban'] as String,
    );
  }
}
