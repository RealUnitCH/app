import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/widgets/handlebars.dart';

typedef FuncValidateQR = bool Function(String? code, List<int>? rawBytes);

var isQrScannerShown = false;

class QRData {
  final String? value;
  final Uint8List data;

  const QRData(this.value, this.data);

  QRData.fromBarcode(Barcode barcode)
      : value = barcode.rawValue,
        data = barcode.rawBytes ?? Uint8List(0);
}

bool _defaultQRValidate(String? code, List<int>? rawBytes) => rawBytes?.isNotEmpty == true;

Future<QRData?> presentQRScanner(BuildContext context, [FuncValidateQR? validateQR]) async {
  isQrScannerShown = true;
  try {
    final result = await showCupertinoSheet<QRData>(
      context: context,
      builder: (_) => QRScanner(validateQR: validateQR ?? _defaultQRValidate),
    );
    isQrScannerShown = false;
    return result;
  } catch (e) {
    isQrScannerShown = false;
    rethrow;
  }
}

class QRScanner extends StatefulWidget {
  const QRScanner({super.key, required this.validateQR});

  final FuncValidateQR validateQR;

  @override
  State<QRScanner> createState() => _QRScannerState();
}

class _QRScannerState extends State<QRScanner> {
  bool popped = false;

  void _handleBarcode(BarcodeCapture barcodes) {
    try {
      _handleBarcodeInternal(barcodes);
    } catch (e) {
      // showPopUp<void>(
      //   context: context,
      //   builder: (context) {
      //     return AlertWithOneAction(
      //       alertTitle: S.of(context).error,
      //       alertContent: S.of(context).error_dialog_content,
      //       buttonText: 'ok',
      //       buttonAction: () {
      //         Navigator.of(context).pop();
      //       },
      //     );
      //   },
      // );
      developer.log("QRCode Scanner Error", error: e, name: "QRScanner._handleBarcode");
    }
  }

  void _handleBarcodeInternal(BarcodeCapture barcodes) {
    for (final barcode in barcodes.barcodes) {
      developer.log("${barcode.rawValue} - ${barcode.rawBytes}",
          name: "QRScanner._handleBarcodeInternal", level: 800);
      if (!widget.validateQR(barcode.rawValue, barcode.rawBytes)) continue;
      if (mounted && !popped) {
        setState(() => popped = true);
        Navigator.of(context).pop(QRData.fromBarcode(barcode));
      }
    }
  }

  final MobileScannerController ctrl = MobileScannerController();

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            MobileScanner(onDetect: _handleBarcode, controller: ctrl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Handlebars.horizontal(context)],
            ),
            // SafeArea(
            //   child: Row(
            //       mainAxisAlignment: MainAxisAlignment.end,
            //     children: [
            //       Padding(
            //         padding: const EdgeInsets.only(right: 10),
            //         child: IconButton(
            //           style:
            //               IconButton.styleFrom(backgroundColor: Colors.black26),
            //           padding: const EdgeInsets.all(10),
            //           icon: const Icon(
            //             Icons.close,
            //             size: 25,
            //             color: Colors.white,
            //           ),
            //           onPressed: context.pop,
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomPaint(
                    foregroundPainter: const BorderPainter(),
                    child: SizedBox(
                      width: 200,
                      height: 200,
                      child: Center(
                          child: Text(
                        S.of(context).scan_qr_code,
                        style: const TextStyle(fontSize: 20, color: Colors.white),
                      )),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: ToggleFlashlightButton(controller: ctrl),
                  )
                ],
              ),
            ),
          ],
        ),
      );
}

class BorderPainter extends CustomPainter {
  const BorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    double sh = size.height; // for convenient shortage
    double sw = size.width; // for convenient shortage
    double cornerSide = sh * 0.23; // desirable value for corners side

    Paint paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      // ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    Path path = Path()
      ..moveTo(cornerSide, 0)
      // ..lineTo(0, 0)..lineTo(0, cornerSide)
      ..conicTo(0, 0, 0, cornerSide, 30)
      ..moveTo(0, sh - cornerSide)
      // ..lineTo(0, sh)..lineTo(cornerSide, sh)
      ..conicTo(0, sh, cornerSide, sh, 30)
      ..moveTo(sw - cornerSide, sh)
      // ..lineTo(sw, sh)..lineTo(sw, sh - cornerSide)
      ..conicTo(sw, sh, sw, sh - cornerSide, 30)
      ..moveTo(sw, cornerSide)
      // ..lineTo(sw, 0)..lineTo(sw - cornerSide, 0);
      ..conicTo(sw, 0, sw - cornerSide, 0, 30);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(BorderPainter oldDelegate) => false;

  @override
  bool shouldRebuildSemantics(BorderPainter oldDelegate) => false;
}

class ToggleFlashlightButton extends StatelessWidget {
  const ToggleFlashlightButton({required this.controller, super.key});

  final MobileScannerController controller;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
        valueListenable: controller,
        builder: (context, state, child) {
          if (!state.isInitialized || !state.isRunning) {
            return const SizedBox.shrink();
          }

          switch (state.torchState) {
            case TorchState.off:
              return IconButton(
                style: IconButton.styleFrom(backgroundColor: Colors.black26),
                padding: const EdgeInsets.all(10),
                icon: const Icon(
                  Icons.flashlight_off,
                  size: 25,
                  color: Colors.white,
                ),
                onPressed: controller.toggleTorch,
              );
            case TorchState.on:
              return IconButton(
                style: IconButton.styleFrom(backgroundColor: Colors.black26),
                padding: const EdgeInsets.all(10),
                icon: const Icon(
                  Icons.flashlight_on,
                  size: 25,
                  color: Colors.white,
                ),
                onPressed: controller.toggleTorch,
              );
            default:
              return const SizedBox.shrink();
          }
        },
      );
}
