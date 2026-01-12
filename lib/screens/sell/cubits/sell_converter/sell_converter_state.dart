part of 'sell_converter_cubit.dart';

class SellConverterState extends Equatable {
  final String fiatText;
  final String sharesText;
  final Currency currency;
  final bool loading;

  const SellConverterState({
    this.fiatText = "",
    this.sharesText = "",
    this.currency = Currency.chf,
    this.loading = false,
  });

  SellConverterState copyWith({
    String? fiatText,
    String? sharesText,
    Currency? currency,
    bool? loading,
  }) {
    return SellConverterState(
      fiatText: fiatText ?? this.fiatText,
      sharesText: sharesText ?? this.sharesText,
      currency: currency ?? this.currency,
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object?> get props => [fiatText, sharesText, currency, loading];
}
