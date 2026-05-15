import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:realunit_wallet/packages/utils/xfile_extension.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('xfile_ext_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  XFile writeTempFile(String name, List<int> bytes, {String? mimeType}) {
    final file = File('${tempDir.path}/$name')..writeAsBytesSync(bytes);
    return XFile(file.path, mimeType: mimeType);
  }

  group('XFileToBase64.toBase64DataUri', () {
    test('produces a data URI with the explicit mimeType when provided', () async {
      final xfile = writeTempFile('blob.bin', [1, 2, 3], mimeType: 'image/png');

      final uri = await xfile.toBase64DataUri();

      expect(uri, 'data:image/png;base64,${base64Encode([1, 2, 3])}');
    });

    test('guesses image/png from the .png extension when mimeType is absent', () async {
      final xfile = writeTempFile('photo.png', [10, 20]);

      final uri = await xfile.toBase64DataUri();

      expect(uri.startsWith('data:image/png;base64,'), isTrue);
      expect(uri.endsWith(base64Encode([10, 20])), isTrue);
    });

    test('guesses image/jpeg for .jpg and .jpeg', () async {
      final jpg = writeTempFile('x.jpg', [0]);
      final jpeg = writeTempFile('y.JPEG', [0]);

      expect(await jpg.toBase64DataUri(), startsWith('data:image/jpeg;base64,'));
      // Extension match is case-insensitive (the helper lowercases first).
      expect(await jpeg.toBase64DataUri(), startsWith('data:image/jpeg;base64,'));
    });

    test('guesses application/pdf for .pdf', () async {
      final xfile = writeTempFile('doc.pdf', [0]);

      expect(
        await xfile.toBase64DataUri(),
        startsWith('data:application/pdf;base64,'),
      );
    });

    test('falls back to application/octet-stream for unknown extensions', () async {
      final xfile = writeTempFile('mystery.zzz', [0]);

      expect(
        await xfile.toBase64DataUri(),
        startsWith('data:application/octet-stream;base64,'),
      );
    });

    test('encodes the raw bytes (not the file path) into the base64 segment', () async {
      final bytes = utf8.encode('hello world');
      final xfile = writeTempFile('plain.bin', bytes);

      final uri = await xfile.toBase64DataUri();

      final segment = uri.split(',')[1];
      expect(base64Decode(segment), bytes);
    });
  });
}
