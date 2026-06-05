/// Wire shape of `/v1/realunit/price` and each `/v1/realunit/price/history`
/// entry. The backend omits `chf`/`eur` while no price is published for the
/// timestamp (e.g. the current day before the daily fixing), so both values
/// are nullable. `timestamp` is absent on some spot responses and therefore
/// nullable as well.
class RealUnitPriceDto {
  final double? chf;
  final double? eur;
  final DateTime? timestamp;

  const RealUnitPriceDto({
    required this.chf,
    required this.eur,
    required this.timestamp,
  });

  factory RealUnitPriceDto.fromJson(Map<String, dynamic> json) {
    final timestamp = json['timestamp'];
    return RealUnitPriceDto(
      chf: (json['chf'] as num?)?.toDouble(),
      eur: (json['eur'] as num?)?.toDouble(),
      timestamp: timestamp is String ? DateTime.tryParse(timestamp) : null,
    );
  }
}
