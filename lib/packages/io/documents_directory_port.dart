import 'dart:io';

/// Boundary in front of `package:path_provider` so cubits that need to write
/// temporary files (PDF receipts, tax reports, …) can be unit-tested without
/// hitting the platform channel.
///
/// Production wiring defaults to [PathProviderAdapter], which delegates to
/// `path_provider`. Tests supply a fake that returns a [Directory] under
/// `Directory.systemTemp` (or any other writable location).
///
/// The port intentionally exposes the surface the cubits actually use — today
/// that is `getTemporaryDirectory()`. New methods are added per concrete need
/// rather than mirroring the full `path_provider` API up-front.
abstract class DocumentsDirectoryPort {
  /// Returns a writable temporary directory whose contents may be purged by
  /// the OS at any time. Equivalent to `path_provider.getTemporaryDirectory`.
  Future<Directory> getTemporaryDirectory();
}
