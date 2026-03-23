import 'dart:convert';

import 'package:image_picker/image_picker.dart';

extension XFileToBase64 on XFile {
  /// Converts the file to a base64 data URI string
  Future<String> toBase64DataUri() async {
    final bytes = await readAsBytes();
    final mime = mimeType ?? _guessMimeType(name);
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }

  static String _guessMimeType(String name) {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'pdf' => 'application/pdf',
      _ => 'application/octet-stream',
    };
  }
}
