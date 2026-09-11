abstract final class WalletConnectAllowlist {
  static const allowedRegistrableDomains = [
    'aktionariat.com',
    'frankencoin.com',
  ];

  /// Aktionariat tenant host for RealUnit (same org, not a third provider).
  static const allowedExactHosts = ['shares.realunit.ch'];

  static const unsupportedProviderMessage =
      'WalletConnect is not supported for this provider.';

  static bool isAllowedOrigin(String? url) {
    final host = hostOf(url);
    if (host == null) return false;
    if (allowedExactHosts.contains(host)) return true;
    return allowedRegistrableDomains.any(
      (domain) => host == domain || host.endsWith('.$domain'),
    );
  }

  static String? hostOf(String? url) {
    final value = url?.trim();
    if (value == null || value.isEmpty) return null;

    Uri? uri = Uri.tryParse(value);
    // Non-https schemes (`http:`, `mailto:`, `javascript:`) must not fall
    // through to the bare-host prepend (`https://mailto:x@aktionariat.com`
    // would parse as host `aktionariat.com`).
    if (uri != null && uri.scheme.isNotEmpty && uri.scheme != 'https') {
      return null;
    }
    if (uri == null || uri.host.isEmpty) {
      // Bare host only. Scheme-relative (`//host`) and userinfo (`user@host`)
      // stay fail-closed.
      if (value.contains('://') || value.startsWith('//') || value.contains('@')) {
        return null;
      }
      uri = Uri.tryParse('https://$value');
    }
    if (uri == null ||
        uri.host.isEmpty ||
        uri.scheme != 'https' ||
        uri.userInfo.isNotEmpty) {
      return null;
    }

    var host = uri.host.toLowerCase();
    while (host.endsWith('.')) {
      host = host.substring(0, host.length - 1);
    }
    if (host.startsWith('www.')) host = host.substring(4);
    return host.isEmpty ? null : host;
  }
}
