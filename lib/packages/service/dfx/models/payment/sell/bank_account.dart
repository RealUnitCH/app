import 'package:equatable/equatable.dart';

class BankAccount extends Equatable {
  final String? name;
  final String iban;

  const BankAccount({
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

  @override
  List<Object?> get props => [name, iban];
}
