import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';

part 'settings_seed_state.dart';

class SettingsSeedCubit extends Cubit<SettingsSeedState> {
  final SoftwareWallet wallet;

  SettingsSeedCubit(this.wallet) : super(SettingsSeedState(wallet.seed));

  void toggleShowSeed() => emit(state.copyWith(showSeed: !state.showSeed));
}
