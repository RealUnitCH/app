import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/screens/hardware_connect_bitbox/connect_bitbox_page.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';

/// Opens the BitBox pairing flow as a bottom sheet for the
/// already-onboarded user, e.g. after the BitBox has been disconnected and a
/// later action (buy info refresh, sell signing, user-data fetch) needs the
/// device back.
///
/// Emits `SyncWalletServicesEvent` instead of `LoadWalletEvent` because the
/// wallet itself is unchanged — only the underlying transport needs to be
/// re-attached. Returns `true` if the user completed the re-pair.
Future<bool> showBitboxReconnectSheet(BuildContext context) async {
  final homeBloc = context.read<HomeBloc>();
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => ConnectBitboxPage(
      onFinish: (wallet) {
        homeBloc.add(SyncWalletServicesEvent(wallet));
        Navigator.of(sheetContext).pop(true);
      },
    ),
  );
  return result == true;
}
