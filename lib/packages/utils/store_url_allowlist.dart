enum StoreUrlChannel { appStore, playStore, githubReleases }

final _githubReleaseTagPattern = RegExp(r'^v\d+\.\d+\.\d+$');

/// Returns the original URL if it is an allowlisted HTTPS store URL for [channel], else null.
String? parseAllowlistedStoreUrl(String? raw, StoreUrlChannel channel) {
  if (raw == null || raw.isEmpty) return null;

  final uri = Uri.tryParse(raw);
  if (uri == null) return null;
  if (!uri.isScheme('https')) return null;
  if (uri.userInfo.isNotEmpty) return null;
  if (uri.pathSegments.any((segment) => segment == '.' || segment == '..')) {
    return null;
  }

  switch (channel) {
    case StoreUrlChannel.appStore:
      if (uri.host != 'apps.apple.com' && uri.host != 'itunes.apple.com') {
        return null;
      }
      if (!uri.pathSegments.contains('app')) return null;
      return raw;
    case StoreUrlChannel.playStore:
      if (uri.host != 'play.google.com') return null;
      if (uri.path != '/store/apps/details' && uri.path != '/store/apps/details/') {
        return null;
      }
      final ids = uri.queryParametersAll['id'];
      if (ids == null || ids.length != 1 || ids.first != 'swiss.realunit.app') {
        return null;
      }
      return raw;
    case StoreUrlChannel.githubReleases:
      if (uri.host != 'github.com') return null;
      if (uri.path == '/RealUnitCH/app/releases' ||
          uri.path == '/RealUnitCH/app/releases/') {
        return raw;
      }
      const tagPrefix = '/RealUnitCH/app/releases/tag/';
      if (uri.path.startsWith(tagPrefix)) {
        final tag = uri.path.substring(tagPrefix.length);
        if (_githubReleaseTagPattern.hasMatch(tag)) return raw;
      }
      return null;
  }
}
