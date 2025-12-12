import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/seedqr.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/widgets/qr_scanner.dart';

part 'restore_wallet_state.dart';

class RestoreWalletCubit extends Cubit<RestoreWalletState> {
  RestoreWalletCubit(this._walletService) : super(RestoreWalletState());

  final WalletService _walletService;

  void restoreWallet(String seed) async {
    emit(RestoreWalletState(isLoading: true));

    final normalizedSeed = seed.split(" ").where((element) => element.isNotEmpty).join(" ");

    final wallet = await _walletService.createWallet(
      name: "Obi-Wallet-Kenobi",
      seed: normalizedSeed,
    );

    emit(
      RestoreWalletState(
        isLoading: false,
        wallet: wallet,
      ),
    );
  }

  Future<void> restoreWalletFromSeedQR(BuildContext context) async {
    if (context.mounted) {
      emit(RestoreWalletState(isLoading: true));

      final data = await presentQRScanner(
        context,
        (String? code, List<int>? rawBytes) =>
            rawBytes?.isNotEmpty == true && isSeedQr(code ?? "") || isCompactSeedQr(rawBytes ?? []),
      );

      String? seed;
      if (isSeedQr(data?.value ?? "")) {
        seed = getSeedFromSeedQr(data!.value!);
      } else if (isCompactSeedQr(data?.data ?? [])) {
        seed = getSeedFromCompactSeedQr(data!.data);
      }

      if (seed != null) {
        final wallet = await _walletService.createWallet(
          name: "Obi-Wallet-Kenobi",
          seed: seed,
        );
        emit(
          RestoreWalletState(
            isLoading: false,
            wallet: wallet,
          ),
        );
      } else {
        emit(
          RestoreWalletState(isLoading: false),
        );
      }
    }
  }
}
