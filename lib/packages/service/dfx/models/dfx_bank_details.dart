class BankDetails {
  final String recipient;
  final String address;
  final String iban;
  final String bic;
  final String bankName;
  final String currency;

  const BankDetails({
    required this.recipient,
    required this.address,
    required this.iban,
    required this.bic,
    required this.bankName,
    required this.currency,
  });

  factory BankDetails.fromJson(Map<String, dynamic> json) => BankDetails(
        recipient: json['recipient'],
        address: json['address'],
        iban: json['iban'],
        bic: json['bic'],
        bankName: json['bankName'],
        currency: json['currency'],
      );
}
