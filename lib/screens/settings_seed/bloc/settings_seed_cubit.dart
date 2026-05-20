import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';

part 'settings_seed_state.dart';

class SettingsSeedCubit extends Cubit<SettingsSeedState> {
  final AppStore _appStore;

  // Seed the state synchronously when the wallet is already a full
  // SoftwareWallet so the first render of MnemonicReadOnlyField sees the
  // 12 words. With the post-#461 view-wallet model the initial state could
  // briefly be empty, which trips MnemonicReadOnlyField's `length == 12`
  // assert and crashes the screen on open.
  SettingsSeedCubit(this._appStore) : super(SettingsSeedState(_initialSeed(_appStore))) {
    _loadSeed();
  }

  static String _initialSeed(AppStore store) {
    final wallet = store.wallet;
    return wallet is SoftwareWallet ? wallet.seed : '';
  }

  Future<void> _loadSeed() async {
    // Revealing the recovery phrase needs the actual mnemonic in memory —
    // promote a view-wallet to its unlocked form before reading the seed.
    await _appStore.ensureUnlocked();
    final wallet = _appStore.wallet as SoftwareWallet;
    if (state.seed != wallet.seed) emit(SettingsSeedState(wallet.seed));
  }

  void toggleShowSeed() => emit(state.copyWith(showSeed: !state.showSeed));
}
