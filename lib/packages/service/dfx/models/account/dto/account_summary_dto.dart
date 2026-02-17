class AccountSummaryDto {
  final String address;
  final int addressType;
  final String balance;
  final DateTime lastUpdated;
  final List<HistoricalBalanceDto> historicalBalances;

  AccountSummaryDto({
    required this.address,
    required this.addressType,
    required this.balance,
    required this.lastUpdated,
    required this.historicalBalances,
  });

  factory AccountSummaryDto.fromJson(Map<String, dynamic> json) {
    return AccountSummaryDto(
      address: json['address'] as String,
      addressType: json['addressType'] as int,
      balance: json['balance'] as String,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      historicalBalances: (json['historicalBalances'] as List)
          .map((e) => HistoricalBalanceDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class HistoricalBalanceDto {
  final String balance;
  final DateTime timestamp;
  final double? valueChf;
  final double? valueEur;

  HistoricalBalanceDto({
    required this.balance,
    required this.timestamp,
    this.valueChf,
    this.valueEur,
  });

  factory HistoricalBalanceDto.fromJson(Map<String, dynamic> json) {
    return HistoricalBalanceDto(
      balance: json['balance'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      valueChf: (json['valueChf'] as num?)?.toDouble(),
      valueEur: (json['valueEur'] as num?)?.toDouble(),
    );
  }
}
