import 'dart:convert';

class PayQuoteDto {
  final String? merchantName;
  final double billChf;
  final double shares;
  final double proceedsChf;
  final double feeChf;
  final double feeRealu;

  const PayQuoteDto({
    required this.merchantName,
    required this.billChf,
    required this.shares,
    required this.proceedsChf,
    required this.feeChf,
    required this.feeRealu,
  });

  String encode() {
    final payload = <String, Object>{'kind': 'payQuote'};
    final name = merchantName;
    if (name != null && name.trim().isNotEmpty) {
      payload['merchantName'] = name;
    }
    payload['billChf'] = billChf;
    payload['shares'] = shares;
    payload['proceedsChf'] = proceedsChf;
    payload['feeChf'] = feeChf;
    payload['feeRealu'] = feeRealu;
    return jsonEncode(payload);
  }

  factory PayQuoteDto.fromJson(Map<String, dynamic> json) {
    final kind = json['kind'] as String?;
    if (kind != null && kind != 'payQuote') {
      throw const FormatException();
    }
    return PayQuoteDto(
      merchantName: json['merchantName'] as String?,
      billChf: _finite(json['billChf'] as num),
      shares: _finite(json['shares'] as num),
      proceedsChf: _finite(json['proceedsChf'] as num),
      feeChf: _finite(json['feeChf'] as num),
      feeRealu: _finite(json['feeRealu'] as num),
    );
  }

  /// A stored booking is a JSON string and must name `payQuote`.
  static PayQuoteDto? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final json = Map<String, dynamic>.from(decoded);
      final kind = json['kind'] as String?;
      if (kind != 'payQuote') return null;
      return PayQuoteDto.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// History may omit `kind`. A non-object, including a referral decimal, stays null.
  static PayQuoteDto? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    try {
      return PayQuoteDto.fromJson(Map<String, dynamic>.from(raw));
    } catch (_) {
      return null;
    }
  }

  static double _finite(num value) {
    final asDouble = value.toDouble();
    if (!asDouble.isFinite) {
      throw const FormatException();
    }
    return asDouble;
  }
}
