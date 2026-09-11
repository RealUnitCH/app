// @no-integration-test: the QR scanner is camera/MethodChannel-coupled
// (mobile_scanner) and can only be exercised on a real device with a live
// camera. Pairing is unit-tested via WalletConnectService; this page is
// covered by the scanner-navigation catalog test.
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/walletconnect/walletconnect_uri.dart';
import 'package:realunit_wallet/screens/walletconnect/walletconnect_session_page.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/scanner/push_then_rearm.dart';
import 'package:realunit_wallet/widgets/scanner/qr_scanner_view.dart';

class WalletConnectScanPage extends StatelessWidget {
  const WalletConnectScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WalletConnectScanCubit(),
      child: const WalletConnectScanView(),
    );
  }
}

class WalletConnectScanView extends StatelessWidget {
  const WalletConnectScanView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WalletConnectScanCubit, WalletConnectScanState>(
      listenWhen: (previous, current) =>
          (current is WalletConnectScanDecoded && previous is! WalletConnectScanDecoded) ||
          (current is WalletConnectScanInvalid && previous is! WalletConnectScanInvalid),
      listener: (context, state) {
        if (state is WalletConnectScanInvalid) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.of(context).walletConnectScanInvalid),
              backgroundColor: RealUnitColors.status.red600,
            ),
          );
          context.read<WalletConnectScanCubit>().reset();
          return;
        }
        if (state is! WalletConnectScanDecoded) return;
        unawaited(
          pushThenRearm(
            context,
            page: WalletConnectSessionView(pairingUri: state.uri),
            rearm: () => context.read<WalletConnectScanCubit>().reset(),
          ),
        );
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: Text(S.of(context).walletConnectScanTitle)),
          body: QrScannerView(
            onDetect: (raw) => context.read<WalletConnectScanCubit>().onCodeDetected(raw),
            errorBuilder: (context, error) {
              final message = error.errorCode == MobileScannerErrorCode.permissionDenied
                  ? S.of(context).payScanCameraPermissionDenied
                  : S.of(context).payScanCameraUnavailable;
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: RealUnitColors.neutral500,
                    ),
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

class WalletConnectScanCubit extends Cubit<WalletConnectScanState> {
  WalletConnectScanCubit() : super(const WalletConnectScanScanning());

  void onCodeDetected(String raw) {
    if (state is WalletConnectScanDecoded) return;
    final uri = WalletConnectUri.extractPairingUri(raw);
    if (uri == null) {
      emit(const WalletConnectScanInvalid());
      return;
    }
    emit(WalletConnectScanDecoded(uri));
  }

  void reset() => emit(const WalletConnectScanScanning());
}

sealed class WalletConnectScanState extends Equatable {
  const WalletConnectScanState();

  @override
  List<Object?> get props => [];
}

class WalletConnectScanScanning extends WalletConnectScanState {
  const WalletConnectScanScanning();
}

class WalletConnectScanInvalid extends WalletConnectScanState {
  const WalletConnectScanInvalid();
}

class WalletConnectScanDecoded extends WalletConnectScanState {
  final String uri;

  const WalletConnectScanDecoded(this.uri);

  @override
  List<Object?> get props => [uri];
}
