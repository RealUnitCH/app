import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';

part 'settings_seed_state.dart';

class SettingsSeedCubit extends Cubit<SettingsSeedState> {
  final AppStore _appStore;
  final WalletService _walletService;

  // Seed the state synchronously when the wallet is already a full
  // SoftwareWallet so the first render of MnemonicReadOnlyField sees the
  // 12 words. With the post-#461 view-wallet model the initial state could
  // briefly be empty, which trips MnemonicReadOnlyField's `length == 12`
  // assert and crashes the screen on open.
  SettingsSeedCubit(this._appStore, this._walletService)
      : super(SettingsSeedState(_initialSeed(_appStore))) {
    _loadSeed();
  }

  static String _initialSeed(AppStore store) {
    final wallet = store.wallet;
    return wallet is SoftwareWallet ? wallet.seed : '';
  }

  Future<void> _loadSeed() async {
    // Revealing the recovery phrase needs the actual mnemonic in memory —
    // promote a view-wallet to its unlocked form before reading the seed.
    await _walletService.ensureCurrentWalletUnlocked();
    final wallet = _appStore.wallet as SoftwareWallet;
    // copyWith preserves a [showSeed] toggle that may have raced ahead of the
    // unlock so the user's choice isn't dropped on the floor.
    if (state.seed != wallet.seed) emit(state.copyWith(seed: wallet.seed));
  }

  void toggleShowSeed() => emit(state.copyWith(showSeed: !state.showSeed));

  @override
  Future<void> close() async {
    // The mnemonic is on screen only while this cubit is alive — once the user
    // navigates away, drop it back to the locked view so the key isn't
    // resident for the rest of the foreground session.
    await _walletService.lockCurrentWallet();
    return super.close();
  }
}
