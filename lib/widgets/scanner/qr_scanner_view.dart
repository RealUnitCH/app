// @no-integration-test: the QR scanner is camera/MethodChannel-coupled
// (mobile_scanner) and can only be exercised on a real device with a live
// camera. This widget is the shared camera-preview wrapper reused by the OCP
// pay flow (LNURL decode) and the wallet-to-wallet send flow (EVM address
// decode); the per-flow decode logic it feeds is unit-tested in the respective
// cubit tests.
import 'package:flutter/widgets.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Thin wrapper around [MobileScanner] that surfaces the first raw barcode
/// value of each capture via [onDetect]. Keeping the camera/MethodChannel
/// wiring in one widget lets every flow reuse the scanner without duplicating
/// it — each flow decides what the scanned payload means in its own cubit.
class QrScannerView extends StatelessWidget {
  /// Invoked with the raw string value of the first detected barcode in a
  /// capture. Null raw values are filtered out before this is called.
  final ValueChanged<String> onDetect;

  /// Optional error UI builder forwarded to [MobileScanner.errorBuilder].
  /// When null, MobileScanner's own default error handling is used.
  final Widget Function(BuildContext, MobileScannerException, Widget?)? errorBuilder;

  const QrScannerView({
    super.key,
    required this.onDetect,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      onDetect: (capture) {
        final raw = capture.barcodes.firstOrNull?.rawValue;
        if (raw != null) onDetect(raw);
      },
      errorBuilder: errorBuilder,
    );
  }
}
