import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:realunit_wallet/widgets/image_source_sheet.dart';

class ImagePickerSheet {
  static Future<XFile?> show(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => ImageSourceSheet(
        onCamera: () => Navigator.pop(context, ImageSource.camera),
        onLibrary: () => Navigator.pop(context, ImageSource.gallery),
      ),
    );

    if (source == null) return null;
    // @no-integration-test: ImagePickerSheet drives image_picker camera/gallery
    // MethodChannels and can only be exercised on a real device with live media
    // access. Callers (support attach path, KYC FilePickerField) are unit-tested
    // with injected XFiles above this boundary; the sheet itself is out of scope
    // for widget tests.
    return ImagePicker().pickImage(source: source, imageQuality: 80);
  }
}
