import 'dart:io';

import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:realunit_wallet/packages/io/documents_directory_port.dart';

/// Production [DocumentsDirectoryPort] implementation backed by
/// `package:path_provider`. Methods forward 1:1 — no extra behaviour, no
/// caching — so this adapter and the real plugin are interchangeable at
/// runtime.
class PathProviderAdapter implements DocumentsDirectoryPort {
  const PathProviderAdapter();

  @override
  Future<Directory> getTemporaryDirectory() => path_provider.getTemporaryDirectory();
}
