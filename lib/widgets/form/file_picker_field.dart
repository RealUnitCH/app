import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/styles/colors.dart';

class FilePickerField extends StatelessWidget {
  final String label;
  final XFile? selectedFile;
  final ValueChanged<XFile?> onFileSelected;
  final String? Function()? validator;

  const FilePickerField({
    super.key,
    required this.label,
    required this.selectedFile,
    required this.onFileSelected,
    this.validator,
  });

  Future<void> _pickFile(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(S.of(context).choosePhoto),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(S.of(context).choosePhotoLibrary),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 80);
    onFileSelected(file);
  }

  @override
  Widget build(BuildContext context) {
    final error = validator?.call();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              height: 18 / 13,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _pickFile(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: error != null ? RealUnitColors.status.red600 : RealUnitColors.neutral300,
              ),
            ),
            child: selectedFile != null
                ? Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.file(
                          File(selectedFile!.path),
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          selectedFile!.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const Icon(Icons.edit, size: 18, color: RealUnitColors.realUnitBlue),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_a_photo, color: RealUnitColors.neutral400),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: const TextStyle(color: RealUnitColors.neutral400),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  /// Converts the selected file to a base64 data URI string.
  static Future<String?> toBase64DataUri(XFile? file) async {
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    final mimeType = file.mimeType ?? _guessMimeType(file.name);
    return 'data:$mimeType;base64,${base64Encode(bytes)}';
  }

  static String _guessMimeType(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
}
