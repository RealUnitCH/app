import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';

part 'kyc_address_change_state.dart';

class KycAddressChangeCubit extends Cubit<KycAddressChangeState> {
  final DfxKycService _kycService;

  KycAddressChangeCubit({required DfxKycService kycService})
      : _kycService = kycService,
        super(const KycAddressChangeInitial());

  Future<void> submitAddress(
    String url, {
    required String street,
    required String houseNumber,
    required String zip,
    required String city,
    required String country,
  }) async {
    try {
      emit(const KycAddressChangeLoading());
      await _kycService.setData(url, {
        'street': street,
        'houseNumber': houseNumber,
        'zip': zip,
        'city': city,
        'country': country,
      });
      emit(const KycAddressChangeSuccess());
    } catch (e) {
      emit(KycAddressChangeFailure(e.toString()));
    }
  }
}
