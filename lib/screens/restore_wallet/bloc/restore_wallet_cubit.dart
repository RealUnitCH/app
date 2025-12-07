import 'package:bip39/src/wordlists/english.dart' as wordlist;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/seedqr.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/widgets/qr_scanner.dart';

part 'restore_wallet_state.dart';

class RestoreWalletCubit extends Cubit<RestoreWalletState> {
  RestoreWalletCubit(this._walletService) : super(RestoreWalletState(false, false, false));

  final WalletService _walletService;

  void restoreWallet(String seed) async {
    emit(state.copyWith(isLoading: true));

    final normalizedSeed = seed.split(" ").where((element) => element.isNotEmpty).join(" ");

    final wallet = await _walletService.restoreWallet("Obi-Wallet-Kenobi", normalizedSeed);

    emit(state.copyWith(isSeedReady: true, isLoading: false, isRestored: true, wallet: wallet));
  }

  void validateSeed(String seed) {
    final seedWords = seed.split(" ").where((element) => element.isNotEmpty);

    if (seedWords.length == 12 && _containsAll(wordlist.WORDLIST, seedWords)) {
      emit(state.copyWith(isSeedReady: true));
    } else {
      emit(state.copyWith(isSeedReady: false));
    }
  }

  Future<void> restoreWalletFromSeedQR(BuildContext context) async {
    if (context.mounted) {
      emit(state.copyWith(isLoading: true));

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
        final wallet = await _walletService.restoreWallet("Obi-Wallet-Kenobi", seed);
        emit(state.copyWith(isSeedReady: true, isLoading: false, isRestored: true, wallet: wallet));
      } else {
        emit(state.copyWith(isLoading: false, isRestored: false));
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
