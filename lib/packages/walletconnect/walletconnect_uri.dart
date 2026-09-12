abstract final class WalletConnectUri {
  /// Truncated `%` escapes throw [ArgumentError], not [FormatException].
  static T _catchUri<T>(T Function() fn, T fallback) {
    try {
      return fn();
    } on FormatException {
      return fallback;
    } on ArgumentError {
      return fallback;
    }
  }

  static bool isPairingUri(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return false;
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme.toLowerCase() != 'wc') return false;

    final beforeQuery = value.split('?').first;
    final pairing = RegExp(r'^wc:([^@]+)@2$', caseSensitive: false).firstMatch(beforeQuery);
    if (pairing == null || pairing.group(1)!.isEmpty) return false;
    return _catchUri(() {
      return uri.queryParameters['relay-protocol']?.isNotEmpty == true &&
          uri.queryParameters['symKey']?.isNotEmpty == true;
    }, false);
  }

  static String? extractPairingUri(String raw) {
    return _catchUri(() => _extractPairingUriUnguarded(raw), null);
  }

  static String? _extractPairingUriUnguarded(String raw) {
    final value = raw.trim();
    if (isPairingUri(value)) return value;

    final uri = Uri.tryParse(value);
    if (uri == null) return null;

    if (uri.scheme.toLowerCase() == 'intent') {
      final nested = uri.queryParameters['uri'] ??
          uri.fragment.split(';').where((p) => p.startsWith('S.uri=')).firstOrNull?.substring(6);
      if (nested != null) return extractPairingUri(Uri.decodeComponent(nested));
    }

    if (uri.scheme.toLowerCase() != 'realunit-wallet') {
      return null;
    }
    if (!_isWalletConnectRoute(uri, value)) return null;

    final candidate = uri.queryParameters['uri'];
    if (candidate == null || candidate.isEmpty) return null;

    var current = candidate;
    for (var attempt = 0; attempt < 3; attempt++) {
      final trimmed = current.trim();
      if (isPairingUri(trimmed)) return trimmed;
      final decoded = Uri.decodeComponent(trimmed);
      if (decoded == trimmed) return null;
      current = decoded;
    }
    return null;
  }

  static bool isScanDeeplink(String raw) {
    final value = raw.trim();
    final uri = Uri.tryParse(value);
    if (uri == null) return false;

    if (uri.scheme.toLowerCase() == 'intent' &&
        uri.host.toLowerCase() == 'investorpage') {
      return true;
    }

    if (uri.scheme.toLowerCase() != 'realunit-wallet') {
      return false;
    }

    if (uri.host.toLowerCase() == 'investorpage') return true;
    final remainder = _opaqueRemainder(value);
    return remainder == 'investorpage' || remainder.startsWith('investorpage/');
  }

  static bool isWalletConnectInput(String raw) =>
      isPairingUri(raw) || extractPairingUri(raw) != null || isScanDeeplink(raw);

  static bool _isWalletConnectRoute(Uri uri, String raw) {
    if (uri.host.toLowerCase() == 'wc') return true;
    final remainder = _opaqueRemainder(raw);
    return remainder == 'wc' || remainder.startsWith('wc?');
  }

  static String _opaqueRemainder(String raw) {
    const prefix = 'realunit-wallet:';
    if (!raw.toLowerCase().startsWith(prefix)) return '';
    var remainder = raw.substring(prefix.length);
    if (remainder.startsWith('//')) remainder = remainder.substring(2);
    return remainder.split('?').first.toLowerCase();
  }
}
