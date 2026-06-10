import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/screens/hardware_connect_bitbox/bloc/connect_bitbox_cubit.dart';
import 'package:realunit_wallet/screens/hardware_connect_bitbox/connect_bitbox_view.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/setup/di.dart';

/// Full-page host for the BitBox pairing ceremony when an already-persisted
/// BitBox wallet is missing a valid address (the pre-fix data corruption that
/// crashed the dashboard build). Reuses the exact [ConnectBitboxView] from the
/// initial-pairing flow, but wires the cubit's wallet-acquisition step to
/// [WalletService.healCurrentBitboxAddress] so re-pairing backfills the address
/// onto the existing row instead of creating a second wallet.
///
/// On finish it feeds the healed wallet back through [LoadWalletEvent]; the
/// HomeBloc listener in `main` then re-runs `_navigate`, which lands on the
/// dashboard now that the recovery flag is cleared.
class BitboxAddressRecoveryPage extends StatelessWidget {
  const BitboxAddressRecoveryPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: BlocProvider(
      create: (_) => ConnectBitboxCubit(
        getIt<BitboxService>(),
        getIt<WalletService>(),
        // DfxKycService is the smallest registered DFXAuthService — used only as
        // a transport for ensureSignatureFor(account); no KYC-specific calls
        // here. Mirrors ConnectBitboxPage.
        getIt<DfxKycService>(),
        acquireWallet: () => getIt<WalletService>().healCurrentBitboxAddress(),
      ),
      child: ConnectBitboxView(
        onFinish: (wallet) => getIt<HomeBloc>().add(LoadWalletEvent(wallet)),
        // This page is the only navigation-stack entry (reached via `goNamed`),
        // so `context.pop` would throw `GoError`. The BitBox wallet is view-only
        // (keys live on the device, address is deterministically re-derivable by
        // re-pairing), so deleting the corrupted local row is non-destructive:
        // the handler resets HomeState (hasWallet:false,
        // bitboxAddressRecoveryNeeded:false) and `main._navigate` then lands on
        // the welcome/onboarding screen — no throw, no re-route loop.
        onCancel: () => getIt<HomeBloc>().add(const DeleteCurrentWalletEvent()),
      ),
    ),
  );
}
