import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';

part 'kyc_nationality_state.dart';

class KycNationalityCubit extends Cubit<KycNationalityState> {
  final DfxKycService _kycService;

  KycNationalityCubit(DfxKycService kycService)
    : _kycService = kycService,
      super(const KycNationalityInitial());

  Future<void> registerNationality(String url, Country country) async {
    try {
      emit(const KycNationalityLoading());
      await _kycService.setData(url, {
        'nationality': {'id': country.id},
      });
      emit(const KycNationalitySuccess());
    } catch (e) {
      emit(KycNationalityFailure(e.toString()));
    }
  }
}
