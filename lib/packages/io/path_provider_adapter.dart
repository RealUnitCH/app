import 'dart:io';

import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:realunit_wallet/packages/io/documents_directory_port.dart';

/// Production [DocumentsDirectoryPort] implementation backed by
/// `package:path_provider`. Methods forward 1:1 — no extra behaviour, no
/// caching — so this adapter and the real plugin are interchangeable at
/// runtime.
///
/// The forwarding methods themselves cannot be reached from `flutter test`
/// without a real `path_provider_platform_interface` fake: the boundary the
/// adapter abstracts away IS the platform channel, so testing it would
/// circle back to the same untestable plugin call. The cubits that depend
/// on the port are covered against an in-memory fake instead. The body of
/// the adapter is therefore excluded from line coverage with a block-level
/// `coverage:ignore` — Bug-class risk is zero (1:1 delegation).
// @no-integration-test: thin 1:1 wrapper around `package:path_provider`;
//   no behaviour to verify beyond what the SDK already guarantees.
class PathProviderAdapter implements DocumentsDirectoryPort {
  const PathProviderAdapter();

  // coverage:ignore-start
  @override
  Future<Directory> getTemporaryDirectory() => path_provider.getTemporaryDirectory();

  @override
  Future<Directory> getApplicationDocumentsDirectory() =>
      path_provider.getApplicationDocumentsDirectory();
  // coverage:ignore-end
}
