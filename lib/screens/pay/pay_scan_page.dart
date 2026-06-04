// @no-integration-test: the QR scanner is camera/MethodChannel-coupled
// (mobile_scanner) and can only be exercised on a real device with a live
// camera. The decode logic it feeds is unit-tested in lnurl_decoder_test.dart
// and the cubit behaviour in pay_scan_cubit_test.dart; the camera preview
// itself is out of scope for widget tests.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/pay/cubits/pay_scan/pay_scan_cubit.dart';
import 'package:realunit_wallet/screens/pay/pay_quote_page.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/scanner/qr_scanner_view.dart';

class PayScanPage extends StatelessWidget {
  const PayScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PayScanCubit(),
      child: const PayScanView(),
    );
  }
}

class PayScanView extends StatelessWidget {
  const PayScanView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PayScanCubit, PayScanState>(
      listener: (context, state) {
        if (state is PayScanDecoded) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PayQuotePage(paymentLinkId: state.link.id),
            ),
          );
          // Reset so returning to the scanner re-arms detection.
          context.read<PayScanCubit>().reset();
        }
        if (state is PayScanInvalid) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.of(context).payScanInvalid),
              backgroundColor: RealUnitColors.status.red600,
            ),
          );
          context.read<PayScanCubit>().reset();
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: Text(S.of(context).payScanTitle)),
          body: QrScannerView(
            onDetect: (raw) => context.read<PayScanCubit>().onCodeDetected(raw),
            errorBuilder: (context, error, child) {
              final message = error.errorCode == MobileScannerErrorCode.permissionDenied
                  ? S.of(context).payScanCameraPermissionDenied
                  : S.of(context).payScanCameraUnavailable;
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: RealUnitColors.neutral500),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
