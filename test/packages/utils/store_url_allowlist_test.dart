import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/utils/store_url_allowlist.dart';

void main() {
  group('parseAllowlistedStoreUrl', () {
    test('accepts a good Play Store URL', () {
      const url =
          'https://play.google.com/store/apps/details?id=swiss.realunit.app';

      expect(
        parseAllowlistedStoreUrl(url, StoreUrlChannel.playStore),
        url,
      );
    });

    test('rejects a malware Play Store id', () {
      const url =
          'https://play.google.com/store/apps/details?id=swiss.realunit.app.malware';

      expect(
        parseAllowlistedStoreUrl(url, StoreUrlChannel.playStore),
        isNull,
      );
    });

    test('accepts GitHub releases and rejects download and latest', () {
      const releases = 'https://github.com/RealUnitCH/app/releases';
      const tagged = 'https://github.com/RealUnitCH/app/releases/tag/v1.2.3';
      const download =
          'https://github.com/RealUnitCH/app/releases/download/v1.2.3/app.apk';
      const latest = 'https://github.com/RealUnitCH/app/releases/latest';

      expect(
        parseAllowlistedStoreUrl(releases, StoreUrlChannel.githubReleases),
        releases,
      );
      expect(
        parseAllowlistedStoreUrl(tagged, StoreUrlChannel.githubReleases),
        tagged,
      );
      expect(
        parseAllowlistedStoreUrl(download, StoreUrlChannel.githubReleases),
        isNull,
      );
      expect(
        parseAllowlistedStoreUrl(latest, StoreUrlChannel.githubReleases),
        isNull,
      );
    });

    test('accepts an App Store URL with a locale prefix', () {
      const url = 'https://apps.apple.com/ch/app/id123';

      expect(
        parseAllowlistedStoreUrl(url, StoreUrlChannel.appStore),
        url,
      );
    });

    test('empty or null returns null', () {
      expect(parseAllowlistedStoreUrl(null, StoreUrlChannel.appStore), isNull);
      expect(parseAllowlistedStoreUrl('', StoreUrlChannel.playStore), isNull);
    });

    test('rejects userinfo', () {
      const url = 'https://evil@github.com/RealUnitCH/app/releases';

      expect(
        parseAllowlistedStoreUrl(url, StoreUrlChannel.githubReleases),
        isNull,
      );
    });

    test('rejects http', () {
      const url =
          'http://play.google.com/store/apps/details?id=swiss.realunit.app';

      expect(
        parseAllowlistedStoreUrl(url, StoreUrlChannel.playStore),
        isNull,
      );
    });
  });
}
