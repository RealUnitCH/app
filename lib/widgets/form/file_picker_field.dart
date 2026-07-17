import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:realunit_wallet/styles/colors.dart';

class FilePickerField extends StatelessWidget {
  final String label;
  final XFile? selectedFile;
  final VoidCallback onTap;
  final String? Function()? validator;

  const FilePickerField({
    super.key,
    required this.label,
    required this.selectedFile,
    required this.onTap,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final error = validator?.call();

    return Column(
      crossAxisAlignment: .start,
      children: [
        Padding(
          padding: const .symmetric(horizontal: 12, vertical: 4),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: .bold,
              height: 18 / 13,
            ),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: .infinity,
            height: 76,
            padding: const .symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: .circular(8),
              border: .all(
                color: error != null ? RealUnitColors.status.red600 : RealUnitColors.neutral300,
              ),
            ),
            child: selectedFile != null
                ? Row(
                    spacing: 12.0,
                    children: [
                      ClipRRect(
                        borderRadius: .circular(4),
                        child: Image.file(
                          File(selectedFile!.path),
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          selectedFile!.name,
                          maxLines: 1,
                          overflow: .ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const Icon(
                        Icons.edit_rounded,
                        color: RealUnitColors.realUnitBlue,
                      ),
                    ],
                  )
                : Row(
                    spacing: 8.0,
                    mainAxisAlignment: .center,
                    children: [
                      const Icon(
                        Icons.add_a_photo_rounded,
                        color: RealUnitColors.neutral400,
                      ),
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: .ellipsis,
                          style: const TextStyle(
                            color: RealUnitColors.neutral400,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
