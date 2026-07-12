// Mirror of `FiatDetailDto` on the API
// (`src/shared/models/fiat/dto/fiat.dto.ts`). Carries the per-currency
// capabilities the backend exposes so the app can filter the picker by
// what is actually buyable / sellable for the user, instead of showing
// the local enum unconditionally.
class DfxFiatDto {
  final int id;
  final String name;
  final bool buyable;
  final bool sellable;

  const DfxFiatDto({
    required this.id,
    required this.name,
    required this.buyable,
    required this.sellable,
  });

  factory DfxFiatDto.fromJson(Map<String, dynamic> json) {
    return DfxFiatDto(
      id: json['id'] as int,
      name: json['name'] as String,
      buyable: json['buyable'] as bool? ?? false,
      sellable: json['sellable'] as bool? ?? false,
    );
  }
}
