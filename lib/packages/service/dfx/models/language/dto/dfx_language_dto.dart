// Mirror of `LanguageDto` on the API
// (`src/shared/models/language/dto/language.dto.ts`). The backend is the
// authority on which languages are enabled in production; the app filters
// its picker by `enable: true` instead of shipping a hardcoded list.
class DfxLanguageDto {
  final int id;
  final String symbol;
  final String name;
  final String foreignName;
  final bool enable;

  const DfxLanguageDto({
    required this.id,
    required this.symbol,
    required this.name,
    required this.foreignName,
    required this.enable,
  });

  factory DfxLanguageDto.fromJson(Map<String, dynamic> json) {
    return DfxLanguageDto(
      id: json['id'] as int,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      foreignName: json['foreignName'] as String,
      enable: json['enable'] as bool? ?? true,
    );
  }
}
