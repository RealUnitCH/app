import 'package:equatable/equatable.dart';
import 'package:realunit_wallet/styles/currency.dart';

class BuyState extends Equatable {
  final String chfText;
  final String sharesText;
  final Currency currency;
  final bool loading;

  const BuyState({
    this.chfText = "",
    this.sharesText = "",
    this.currency = Currency.chf,
    this.loading = false,
  });

  BuyState copyWith({
    String? chfText,
    String? sharesText,
    Currency? currency,
    bool? loading,
  }) {
    return BuyState(
      chfText: chfText ?? this.chfText,
      sharesText: sharesText ?? this.sharesText,
      currency: currency ?? this.currency,
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object?> get props => [chfText, sharesText, currency, loading];
}
