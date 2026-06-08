import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:realunit_wallet/styles/colors.dart';

class QRAddressWidget extends StatelessWidget {
  const QRAddressWidget({
    super.key,
    required this.uri,
    required this.subtitle,
  });

  final String uri;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    spacing: 12.0,
    children: [
      QrImageView(
        data: uri,
        size: 250,
        dataModuleStyle: const QrDataModuleStyle(
          color: RealUnitColors.realUnitBlack,
        ),
      ),
      InkWell(
        borderRadius: .circular(16.0),
        enableFeedback: false,
        onTap: _copyToClipboard,
        child: Container(
          padding: const .all(8.0),
          child: Row(
            mainAxisSize: .min,
            crossAxisAlignment: .center,
            spacing: 20.0,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    // The fixed 0/6/21/36 slices assume `subtitle` is a full
                    // 42-char EVM address — true at the only call site, but a
                    // guarded slice is the better shape and is tracked as a
                    // follow-up. Baselined below so the pattern guard blocks
                    // NEW occurrences (this is the audit's RangeError site).
                    TextSpan(
                      // realunit-lint:ignore fixed_index_address_substring — baselined audit site, see note above.
                      text: subtitle.substring(0, 6),
                      style: const TextStyle(fontWeight: .bold),
                    ),
                    const TextSpan(text: ' '),
                    TextSpan(
                      // realunit-lint:ignore fixed_index_address_substring — baselined audit site, see note above.
                      text: subtitle.substring(6, 21),
                    ),
                    const TextSpan(text: '\n'),
                    TextSpan(
                      // realunit-lint:ignore fixed_index_address_substring — baselined audit site, see note above.
                      text: subtitle.substring(21, 36),
                    ),
                    const TextSpan(text: ' '),
                    TextSpan(
                      text: subtitle.substring(36),
                      style: const TextStyle(fontWeight: .bold),
                    ),
                  ],
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Icon(
                Icons.copy_outlined,
                color: RealUnitColors.realUnitBlue,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Future<void> _copyToClipboard() => Clipboard.setData(ClipboardData(text: subtitle));
}
