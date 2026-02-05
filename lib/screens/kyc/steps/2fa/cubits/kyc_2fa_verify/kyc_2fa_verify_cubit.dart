import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';

part 'kyc_2fa_verify_state.dart';

class Kyc2FaVerifyCubit extends Cubit<Kyc2FaVerifyState> {
  final DfxKycService _dfxKycService;

  Kyc2FaVerifyCubit(DfxKycService dfxKycService)
    : _dfxKycService = dfxKycService,
      super(Kyc2FaVerifyInitial());

  Future<void> verifyCode(String code) async {
    try {
      emit(Kyc2FaVerifyLoading());
      await _dfxKycService.verify2FaCode(code);
      emit(Kyc2FaVerifySuccess());
    } catch (e) {
      emit(Kyc2FaVerifyFailure(errorMessage: e.toString()));
    }
  }
}
