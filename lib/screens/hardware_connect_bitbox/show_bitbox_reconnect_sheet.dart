import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/screens/hardware_connect_bitbox/connect_bitbox_page.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/setup/di.dart';

/// Opens the BitBox pairing flow as a bottom sheet for the
/// already-onboarded user, e.g. after the BitBox has been disconnected and a
/// later action (buy info refresh, sell signing, user-data fetch) needs the
/// device back.
///
/// Emits `SyncWalletServicesEvent` instead of `LoadWalletEvent` because the
/// wallet itself is unchanged — only the underlying transport needs to be
/// re-attached. A null acquireWallet reuses the paired BitBox row and does
/// not create a second one or make it current. A BitBox that already sits
/// beside the software wallet passes the existing row, so
/// reconnect does not create a second one or make it current. Returns `true`
/// if the user completed the re-pair.
Future<bool> showBitboxReconnectSheet(
  BuildContext context, {
  Future<BitboxWallet> Function()? acquireWallet,
}) async {
  final homeBloc = context.read<HomeBloc>();
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => ConnectBitboxPage(
      acquireWallet: acquireWallet ?? getIt<WalletService>().existingBitboxWallet,
      onFinish: (wallet) {
        homeBloc.add(SyncWalletServicesEvent(wallet));
        Navigator.of(sheetContext).pop(true);
      },
    ),
  );
  return result == true;
}
