part of 'sell_bank_accounts_cubit.dart';

abstract class SellBankAccountsState extends Equatable {
  final List<BankAccount> accounts;
  const SellBankAccountsState(this.accounts);

  @override
  List<Object?> get props => [accounts];
}

class SellBankAccountsInitial extends SellBankAccountsState {
  const SellBankAccountsInitial() : super(const []);
}

class SellBankAccountsLoading extends SellBankAccountsState {
  const SellBankAccountsLoading(super.accounts);
}

class SellBankAccountsSuccess extends SellBankAccountsState {
  const SellBankAccountsSuccess(super.accounts);
}

class SellBankAccountsLoadFailure extends SellBankAccountsState {
  const SellBankAccountsLoadFailure() : super(const []);
}

class SellBankAccountsAddFailure extends SellBankAccountsState {
  final String message;

  const SellBankAccountsAddFailure(super.accounts, this.message);

  @override
  List<Object?> get props => [accounts, message];
}

class SellBankAccountsUpdateFailure extends SellBankAccountsState {
  const SellBankAccountsUpdateFailure(super.accounts);
}
