part of 'sell_converter_cubit.dart';

class SellConverterState extends Equatable {
  final String fiatText;
  final String sharesText;
  final Currency currency;
  final bool loading;
  final bool priceUnavailable;

  const SellConverterState({
    this.fiatText = '',
    this.sharesText = '',
    this.currency = Currency.chf,
    this.loading = false,
    this.priceUnavailable = false,
  });

  SellConverterState copyWith({
    String? fiatText,
    String? sharesText,
    Currency? currency,
    bool? loading,
    bool? priceUnavailable,
  }) {
    return SellConverterState(
      fiatText: fiatText ?? this.fiatText,
      sharesText: sharesText ?? this.sharesText,
      currency: currency ?? this.currency,
      loading: loading ?? this.loading,
      priceUnavailable: priceUnavailable ?? this.priceUnavailable,
    );
  }

  @override
  List<Object?> get props => [fiatText, sharesText, currency, loading, priceUnavailable];
}
