import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/settings/settings_page.dart';

void main() {
  test('network row stays hidden until insider unlock outside debug', () {
    expect(
      showSettingsNetworkRow(debugMode: false, insiderUnlocked: false),
      isFalse,
    );
    expect(
      showSettingsNetworkRow(debugMode: false, insiderUnlocked: true),
      isTrue,
    );
    expect(
      showSettingsNetworkRow(debugMode: true, insiderUnlocked: false),
      isTrue,
    );
    expect(
      showSettingsNetworkRow(debugMode: true, insiderUnlocked: true),
      isTrue,
    );
  });
}
