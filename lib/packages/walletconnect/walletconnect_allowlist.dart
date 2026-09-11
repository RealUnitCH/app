abstract final class WalletConnectAllowlist {
  static const allowedRegistrableDomains = [
    'aktionariat.com',
    'frankencoin.com',
  ];

  static const unsupportedProviderMessage =
      'WalletConnect is not supported for this provider.';

  static bool isAllowedOrigin(String? url) {
    final host = hostOf(url);
    if (host == null) return false;
    return allowedRegistrableDomains.any(
      (domain) => host == domain || host.endsWith('.$domain'),
    );
  }

  static String? hostOf(String? url) {
    final value = url?.trim();
    if (value == null || value.isEmpty) return null;

    Uri? uri = Uri.tryParse(value);
    if (uri == null || uri.host.isEmpty) {
      uri = Uri.tryParse('https://$value');
    }
    if (uri == null || uri.host.isEmpty) return null;

    var host = uri.host.toLowerCase();
    if (host.startsWith('www.')) host = host.substring(4);
    return host.isEmpty ? null : host;
  }
}
