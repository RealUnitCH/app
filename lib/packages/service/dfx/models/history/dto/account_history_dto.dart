import 'dart:convert';

import 'package:realunit_wallet/screens/pay/pay_quote_parts.dart';

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
  final DateTime timestamp;
  final String txHash;
  final TransferDto? transfer;
  final String? category;
  final PayQuoteBreakdown? payment;

  const HistoryEventDto({
    required this.timestamp,
    required this.txHash,
    this.transfer,
    this.category,
    this.payment,
  });

  factory HistoryEventDto.fromJson(Map<String, dynamic> json) {
    return HistoryEventDto(
      timestamp: DateTime.parse(json['timestamp'] as String),
      txHash: json['txHash'] as String,
      transfer: json['transfer'] != null
          ? TransferDto.fromJson(json['transfer'] as Map<String, dynamic>)
          : null,
      category: json['category'] as String?,
      payment: _paymentBreakdown(json['payment']),
    );
  }
}

PayQuoteBreakdown? _paymentBreakdown(Object? raw) {
  if (raw is! Map) return null;
  final payload = <String, Object?>{};
  for (final entry in raw.entries) {
    final key = entry.key;
    if (key is! String) return null;
    payload[key] = entry.value;
  }
  if (payload['kind'] == null) {
    payload['kind'] = 'payQuote';
  }
  try {
    return PayQuoteBreakdown.tryParse(jsonEncode(payload));
  } catch (_) {
    return null;
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
