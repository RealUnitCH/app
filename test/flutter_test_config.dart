import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:realunit_wallet/styles/themes.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      theme: realUnitTheme,
      platformGoldensConfig: PlatformGoldensConfig(
        enabled: true,
        platforms: {HostPlatform.macOS},
        renderShadows: true,
      ),
      ciGoldensConfig: const CiGoldensConfig(enabled: false),
    ),
    run: () async => testMain(),
  );
}
