import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_allowlist_service.dart';
import 'package:realunit_wallet/screens/buy/cubit/buy_allowlist/buy_allowlist_state.dart';

class BuyAllowlistCubit extends Cubit<BuyAllowlistState> {
  final DfxAllowlistService _allowlistService;

  BuyAllowlistCubit(this._allowlistService) : super(BuyAllowlistState());

  Future<void> checkAddress() async {
    emit(state.copyWith(loading: true));

    try {
      final status = await _allowlistService.checkAllowlist();
      emit(state.copyWith(
        canReceive: status.canReceive,
        isForbidden: status.isForbidden,
        isPowerlisted: status.isPowerlisted,
        loading: false,
      ));
    } catch (e) {
      developer.log(e.toString());
      emit(state.copyWith(loading: false));
    }
  }
}
