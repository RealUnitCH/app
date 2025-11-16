import 'package:bip39/src/wordlists/english.dart' as wordlist;
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/seedqr.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/widgets/qr_scanner.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RestoreWalletState {
  final bool isSeedReady;
  final bool isLoading;
  final bool isRestored;
  final Wallet? wallet;

  RestoreWalletState(this.isSeedReady, this.isLoading, this.isRestored,
      [this.wallet]);
}

class RestoreWalletCubit extends Cubit<RestoreWalletState> {
  RestoreWalletCubit(this._walletService)
      : super(RestoreWalletState(false, false, false));

  final WalletService _walletService;

  void restoreWallet(String seed) async {
    emit(RestoreWalletState(state.isSeedReady, true, false));

    final normalizedSeed =
        seed.split(" ").where((element) => element.isNotEmpty).join(" ");

    final wallet =
        await _walletService.restoreWallet("Obi-Wallet-Kenobi", normalizedSeed);

    emit(RestoreWalletState(true, false, true, wallet));
  }

  void validateSeed(String seed) {
    final seedWords = seed.split(" ").where((element) => element.isNotEmpty);

    if (seedWords.length == 12 && _containsAll(wordlist.WORDLIST, seedWords)) {
      emit(RestoreWalletState(true, state.isLoading, false));
    } else {
      emit(RestoreWalletState(false, state.isLoading, false));
    }
  }

  Future<void> restoreWalletFromSeedQR(BuildContext context) async {
    if (context.mounted) {
      emit(RestoreWalletState(state.isSeedReady, true, false));

      final data = await presentQRScanner(
        context,
        (String? code, List<int>? rawBytes) =>
            rawBytes?.isNotEmpty == true && isSeedQr(code ?? "") ||
            isCompactSeedQr(rawBytes ?? []),
      );

      String? seed;
      if (isSeedQr(data?.value ?? "")) {
        seed = getSeedFromSeedQr(data!.value!);
      } else if (isCompactSeedQr(data?.data ?? [])) {
        seed = getSeedFromCompactSeedQr(data!.data);
      }

      if (seed != null) {
        final wallet =
            await _walletService.restoreWallet("Obi-Wallet-Kenobi", seed);
        emit(RestoreWalletState(true, false, true, wallet));
      } else {
        emit(RestoreWalletState(state.isSeedReady, false, false));
      }
    }
  }

  bool _containsAll(Iterable a, Iterable b) {
    for (final element in b) {
      if (!a.contains(element)) return false;
    }
    return true;
  }
}
