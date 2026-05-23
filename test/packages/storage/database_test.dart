import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:realunit_wallet/packages/io/documents_directory_port.dart';
import 'package:realunit_wallet/packages/storage/database.dart';

/// Returns a caller-supplied [Directory] in place of
/// `path_provider.getApplicationDocumentsDirectory`. Each invocation is
/// counted so the test can assert that `getDatabasePath` reaches the port
/// exactly once.
class _FakeDocumentsDirectoryPort implements DocumentsDirectoryPort {
  _FakeDocumentsDirectoryPort(this.docsDirectory);

  final Directory docsDirectory;
  int docsCalls = 0;
  int tempCalls = 0;

  @override
  Future<Directory> getApplicationDocumentsDirectory() async {
    docsCalls++;
    return docsDirectory;
  }

  @override
  Future<Directory> getTemporaryDirectory() async {
    tempCalls++;
    return docsDirectory;
  }
}

void main() {
  group('AppDatabase.getDatabasePath', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('app_database_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('joins the port-provided documents dir with the SQLCipher filename', () async {
      final port = _FakeDocumentsDirectoryPort(tempDir);

      final path = await AppDatabase.getDatabasePath(port);

      expect(path, p.join(tempDir.path, 'wallet.db.enc'));
      expect(port.docsCalls, 1);
      expect(port.tempCalls, 0);
    });

    test('uses the port for every call (no caching of the resolved path)', () async {
      final port = _FakeDocumentsDirectoryPort(tempDir);

      await AppDatabase.getDatabasePath(port);
      await AppDatabase.getDatabasePath(port);

      expect(port.docsCalls, 2);
    });

    test('honours a port that hands back a different directory per call', () async {
      final firstDir = Directory.systemTemp.createTempSync('app_database_first_');
      final secondDir = Directory.systemTemp.createTempSync('app_database_second_');
      addTearDown(() {
        if (firstDir.existsSync()) firstDir.deleteSync(recursive: true);
        if (secondDir.existsSync()) secondDir.deleteSync(recursive: true);
      });

      final dirs = <Directory>[firstDir, secondDir];
      final port = _RotatingDocumentsDirectoryPort(dirs);

      final firstPath = await AppDatabase.getDatabasePath(port);
      final secondPath = await AppDatabase.getDatabasePath(port);

      expect(firstPath, p.join(firstDir.path, 'wallet.db.enc'));
      expect(secondPath, p.join(secondDir.path, 'wallet.db.enc'));
    });
  });
}

/// Hands back each directory in [_directories] in turn; pins that
/// `getDatabasePath` re-resolves the docs dir on every call rather than
/// memoising it.
class _RotatingDocumentsDirectoryPort implements DocumentsDirectoryPort {
  _RotatingDocumentsDirectoryPort(this._directories);

  final List<Directory> _directories;
  int _index = 0;

  @override
  Future<Directory> getApplicationDocumentsDirectory() async {
    final dir = _directories[_index];
    _index++;
    return dir;
  }

  @override
  Future<Directory> getTemporaryDirectory() async => _directories[_index];
}
