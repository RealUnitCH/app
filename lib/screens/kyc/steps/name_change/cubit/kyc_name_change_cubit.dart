import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';

part 'kyc_name_change_state.dart';

class KycNameChangeCubit extends Cubit<KycNameChangeState> {
  final DfxKycService _kycService;

  KycNameChangeCubit({required DfxKycService kycService})
      : _kycService = kycService,
        super(const KycNameChangeInitial());

  Future<void> submitName(String url, String firstName, String lastName) async {
    try {
      emit(const KycNameChangeLoading());
      await _kycService.setData(url, {'firstName': firstName, 'lastName': lastName});
      emit(const KycNameChangeSuccess());
    } catch (e) {
      emit(KycNameChangeFailure(e.toString()));
    }
  }
}
