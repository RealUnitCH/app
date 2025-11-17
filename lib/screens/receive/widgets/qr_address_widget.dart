import 'package:realunit_wallet/styles/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRAddressWidget extends StatelessWidget {
  const QRAddressWidget({super.key, required this.uri, required this.subtitle});

  final String uri;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          QrImageView(
            data: uri,
            // errorCorrectionLevel: errorCorrectionLevel,
            size: 300,
            eyeStyle: const QrEyeStyle(color: RealUnitColors.realUnitBlack),
            dataModuleStyle: const QrDataModuleStyle(
              color: RealUnitColors.realUnitBlack,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 10),
            child: InkWell(
              enableFeedback: false,
              onTap: _copyToClipboard,
              child: Container(
                padding: const EdgeInsets.all(10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(
                          text: subtitle.substring(0, 6),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: " "),
                        TextSpan(
                          text: subtitle.substring(6, 21),
                        ),
                        const TextSpan(text: "\n"),
                        TextSpan(
                          text: subtitle.substring(21, 36),
                        ),
                        const TextSpan(text: " "),
                        TextSpan(
                          text: subtitle.substring(36),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ]),
                      style: const TextStyle(
                        fontSize: 18,
                        fontFamily: 'Monospace',
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 20),
                      child: Icon(
                        Icons.copy,
                        size: 16,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      );

  Future<void> _copyToClipboard() =>
      Clipboard.setData(ClipboardData(text: subtitle));
}
