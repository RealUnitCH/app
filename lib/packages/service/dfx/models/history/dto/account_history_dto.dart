class AccountHistoryDto {
  final String address;
  final List<HistoryEventDto> history;
  final int totalCount;

  const AccountHistoryDto({
    required this.address,
    required this.history,
    required this.totalCount,
  });

  factory AccountHistoryDto.fromJson(Map<String, dynamic> json) {
    return AccountHistoryDto(
      address: json['address'] as String,
      history: (json['history'] as List<dynamic>)
          .map((e) => HistoryEventDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: json['totalCount'] as int,
    );
  }
}

class HistoryEventDto {
  final String? id;
  final DateTime timestamp;
  final String txHash;
  final TransferDto? transfer;
  final String? category;

  const HistoryEventDto({
    this.id,
    required this.timestamp,
    required this.txHash,
    this.transfer,
    this.category,
  });

  factory HistoryEventDto.fromJson(Map<String, dynamic> json) {
    return HistoryEventDto(
      id: json['id'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      txHash: json['txHash'] as String,
      transfer: json['transfer'] != null
          ? TransferDto.fromJson(json['transfer'] as Map<String, dynamic>)
          : null,
      category: json['category'] as String?,
    );
  }
}

class TransferDto {
  final String from;
  final String to;
  final String value;

  const TransferDto({
    required this.from,
    required this.to,
    required this.value,
  });

  factory TransferDto.fromJson(Map<String, dynamic> json) {
    return TransferDto(
      from: json['from'] as String,
      to: json['to'] as String,
      value: json['value'] as String,
    );
  }
}
