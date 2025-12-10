part of 'buy_converter_cubit.dart';

class BuyConverterState extends Equatable {
  final String fiatText;
  final String sharesText;
  final Currency currency;
  final bool loading;

  const BuyConverterState({
    this.fiatText = "",
    this.sharesText = "",
    this.currency = Currency.chf,
    this.loading = false,
  });

  BuyConverterState copyWith({
    String? fiatText,
    String? sharesText,
    Currency? currency,
    bool? loading,
  }) {
    return BuyConverterState(
      fiatText: fiatText ?? this.fiatText,
      sharesText: sharesText ?? this.sharesText,
      currency: currency ?? this.currency,
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object?> get props => [fiatText, sharesText, currency, loading];
}
