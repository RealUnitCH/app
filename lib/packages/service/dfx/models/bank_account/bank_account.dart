import 'package:equatable/equatable.dart';

class BankAccount extends Equatable {
  final int id;
  final String? name;
  final String iban;
  final bool isActive;

  const BankAccount({
    required this.id,
    required this.iban,
    this.name,
    this.isActive = false,
  });

  @override
  List<Object?> get props => [id];
}
