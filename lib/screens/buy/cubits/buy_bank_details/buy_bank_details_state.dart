part of 'buy_bank_details_cubit.dart';

class BuyBankDetailsState extends Equatable {
  final bool loading;
  final BankDetails? bankDetails;

  const BuyBankDetailsState({
    this.loading = false,
    this.bankDetails,
  });

  BuyBankDetailsState copyWith({
    bool? loading,
    BankDetails? bankDetails,
  }) {
    return BuyBankDetailsState(
      loading: loading ?? this.loading,
      bankDetails: bankDetails ?? this.bankDetails,
    );
  }

  @override
  List<Object?> get props => [loading, bankDetails];
}
