import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';

part 'settings_seed_state.dart';

class SettingsSeedCubit extends Cubit<SettingsSeedState> {
  final AppStore _appStore;

  SettingsSeedCubit(this._appStore) : super(const SettingsSeedState('')) {
    _loadSeed();
  }

  Future<void> _loadSeed() async {
    // Revealing the recovery phrase needs the actual mnemonic in memory —
    // promote a view-wallet to its unlocked form before reading the seed.
    await _appStore.ensureUnlocked();
    final wallet = _appStore.wallet as SoftwareWallet;
    emit(SettingsSeedState(wallet.seed));
  }

  void toggleShowSeed() => emit(state.copyWith(showSeed: !state.showSeed));
}
