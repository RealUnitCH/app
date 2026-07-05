import 'dart:io';

import 'package:flutter/services.dart';
import 'package:realunit_wallet/packages/io/backup_exclusion_port.dart';

/// Production [BackupExclusionPort]. On iOS it forwards the paths to the native
/// side (`AppDelegate`) over a method channel, which sets
/// `URLResourceValues.isExcludedFromBackup = true` on each existing file. On
/// every other platform it is a no-op — Android already disables app backup
/// via `android:allowBackup="false"`, so there is nothing to exclude.
///
/// The method-channel round-trip is the platform boundary itself, so — like
/// [PathProviderAdapter] — its body cannot be exercised under `flutter test`
/// without re-introducing the very plugin it abstracts away. The callers that
/// depend on the port are covered against an in-memory fake instead.
// @no-integration-test: thin platform-channel forwarder; the native effect
//   (NSURLIsExcludedFromBackupKey) is only observable on a real iOS device.
class BackupExclusionAdapter implements BackupExclusionPort {
  const BackupExclusionAdapter();

  static const MethodChannel _channel = MethodChannel('swiss.realunit.app/backup_exclusion');

  // coverage:ignore-start
  @override
  Future<void> excludeFromBackup(List<String> paths) async {
    if (!Platform.isIOS) return;
    await _channel.invokeMethod<void>('excludeFromBackup', paths);
  }
  // coverage:ignore-end
}
