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

  /// A stored booking is a JSON string and must name `payQuote`.
  static PayQuoteDto? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return _fromRaw(jsonDecode(raw), assumeKind: false);
    } catch (_) {
      return null;
    }
  }

  /// History may omit `kind`. A non-object, including a referral decimal, stays null.
  static PayQuoteDto? tryFromJson(Object? raw) => _fromRaw(raw, assumeKind: true);

  static PayQuoteDto? _fromRaw(Object? raw, {required bool assumeKind}) {
    if (raw is! Map) return null;
    final Map<String, dynamic> json;
    try {
      json = Map<String, dynamic>.from(raw);
    } catch (_) {
      return null;
    }
    try {
      final kind = json['kind'];
      if (kind == null) {
        if (!assumeKind) return null;
      } else if (kind as String != 'payQuote') {
        return null;
      }
      final merchant = json['merchantName'];
      final String? merchantName;
      if (merchant == null) {
        merchantName = null;
      } else {
        merchantName = merchant as String;
      }
      return PayQuoteDto(
        merchantName: merchantName,
        billChf: _number(json['billChf']),
        shares: _number(json['shares']),
        proceedsChf: _number(json['proceedsChf']),
        feeChf: _number(json['feeChf']),
        feeRealu: _number(json['feeRealu']),
      );
    } catch (_) {
      return null;
    }
  }

  static double _number(Object? value) {
    if (value is! num) {
      throw const FormatException();
    }
    final asDouble = value.toDouble();
    if (!asDouble.isFinite) {
      throw const FormatException();
    }
    return asDouble;
  }
}
