import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';

part 'kyc_2fa_state.dart';

class Kyc2FaCubit extends Cubit<Kyc2FaState> {
  final DfxKycService _dfxKycService;

  Kyc2FaCubit(DfxKycService dfxKycService) : _dfxKycService = dfxKycService, super(Kyc2FaInitial());

  Future<void> requestCode() async {
    try {
      emit(Kyc2FaLoading());
      await _dfxKycService.request2FaCode();
      emit(Kyc2FaSuccess());
    } catch (e) {
      emit(Kyc2FaFailure(errorMessage: e.toString()));
    }
  }
}
