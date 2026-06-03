import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/config/network_mode.dart';

import '../../helper/pump_app.dart';

void main() {
  group('$NetworkMode', () {
    test('mainnet → isMainnet=true, isTestnet=false, name="Mainnet"', () {
      const mode = NetworkMode.mainnet;

      expect(mode.isMainnet, isTrue);
      expect(mode.isTestnet, isFalse);
      expect(mode.name, 'Mainnet');
    });

    test('testnet → isTestnet=true, isMainnet=false, name="Testnet"', () {
      const mode = NetworkMode.testnet;

      expect(mode.isTestnet, isTrue);
      expect(mode.isMainnet, isFalse);
      expect(mode.name, 'Testnet');
    });

    test('values has exactly the two enum entries (no accidental addition)', () {
      // Catches the case where someone adds a third NetworkMode (e.g. local)
      // without also updating all the switch-on-mode call sites.
      expect(NetworkMode.values, hasLength(2));
      expect(NetworkMode.values, contains(NetworkMode.mainnet));
      expect(NetworkMode.values, contains(NetworkMode.testnet));
    });

    // `localizedName(BuildContext)` is the only piece of NetworkMode that
    // cannot be unit-tested in isolation — it pulls strings through
    // `S.of(context)`. A real widget pump exercises both switch arms
    // against the bundled localizations so the lookup keys
    // `networkMainnet`/`networkTestnet` cannot silently drift.
    group('localizedName(BuildContext)', () {
      testWidgets('mainnet resolves to a non-empty localized string', (tester) async {
        String? resolved;
        await tester.pumpApp(
          Builder(
            builder: (context) {
              resolved = NetworkMode.mainnet.localizedName(context);
              return const SizedBox.shrink();
            },
          ),
        );

        expect(resolved, isNotNull);
        expect(resolved, isNotEmpty);
      });

      testWidgets('testnet resolves to a non-empty localized string distinct from mainnet', (
        tester,
      ) async {
        String? mainnetText;
        String? testnetText;
        await tester.pumpApp(
          Builder(
            builder: (context) {
              mainnetText = NetworkMode.mainnet.localizedName(context);
              testnetText = NetworkMode.testnet.localizedName(context);
              return const SizedBox.shrink();
            },
          ),
        );

        expect(testnetText, isNotNull);
        expect(testnetText, isNotEmpty);
        // Pin the per-arm wiring — if both arms accidentally resolved to
        // the same string key, the user would see "Mainnet" on testnet.
        expect(testnetText, isNot(equals(mainnetText)));
      });
    });
  });
}
