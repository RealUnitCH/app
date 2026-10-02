import 'dart:io';

import 'package:flutter/services.dart';
import 'package:realunit_wallet/packages/io/installer_package_port.dart';

/// Production [InstallerPackagePort]. Android forwards to the native installer
/// package lookup; every other platform is a no-op.
///
/// The method-channel round-trip is the platform boundary, so — like
/// [BackupExclusionAdapter] — this body cannot be exercised under
/// `flutter test` without re-introducing the native plugin. Callers are
/// covered against an in-memory fake instead.
class InstallerPackageAdapter implements InstallerPackagePort {
  const InstallerPackageAdapter();

  static const MethodChannel _channel = MethodChannel(
    'swiss.realunit.app/install_referrer',
  );

  // coverage:ignore-start
  // @no-integration-test: thin platform-channel forwarder; installer package
  //   is only observable on a real Android build.
  @override
  Future<String?> readInstallerPackage() async {
    if (!Platform.isAndroid) return null;
    return _channel.invokeMethod<String>('readInstallerPackage');
  }

  // coverage:ignore-end
}
