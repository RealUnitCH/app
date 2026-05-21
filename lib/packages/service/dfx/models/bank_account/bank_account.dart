import 'package:equatable/equatable.dart';

class BankAccount extends Equatable {
  final int id;
  final String? name;
  final String iban;
  final bool isActive;
  // Backend-tagged "this is the user's preferred account" flag. Drives
  // auto-selection in the sell flow without the app having to guess which
  // active account the user wants.
  final bool isDefault;

  const BankAccount({
    required this.id,
    required this.iban,
    this.name,
    this.isActive = false,
    this.isDefault = false,
  });

  @override
  List<Object?> get props => [id];
}
