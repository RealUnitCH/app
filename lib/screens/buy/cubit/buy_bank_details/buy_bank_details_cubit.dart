import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_bank_details_service.dart';

import 'buy_bank_details_state.dart';

class BuyBankDetailsCubit extends Cubit<BuyBankDetailsState> {
  final DfxBankDetailsService _service;

  BuyBankDetailsCubit(this._service) : super(const BuyBankDetailsState());

  Future<void> fetchBankDetails() async {
    emit(state.copyWith(loading: true));

    try {
      final details = await _service.getBankDetails();
      emit(state.copyWith(
        loading: false,
        bankDetails: details,
      ));
    } catch (e) {
      emit(state.copyWith(loading: false));
    }
  }
}
