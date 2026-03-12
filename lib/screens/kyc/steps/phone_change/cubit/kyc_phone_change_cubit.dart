import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';

part 'kyc_phone_change_state.dart';

class KycPhoneChangeCubit extends Cubit<KycPhoneChangeState> {
  final DfxKycService _kycService;

  KycPhoneChangeCubit({required DfxKycService kycService})
      : _kycService = kycService,
        super(const KycPhoneChangeInitial());

  Future<void> submitPhone(String url, String phone) async {
    try {
      emit(const KycPhoneChangeLoading());
      await _kycService.setData(url, {'phone': phone});
      emit(const KycPhoneChangeSuccess());
    } catch (e) {
      emit(KycPhoneChangeFailure(e.toString()));
    }
  }
}
