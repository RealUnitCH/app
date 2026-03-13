import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_level.dart';

part 'settings_edit_address_state.dart';

class SettingsEditAddressCubit extends Cubit<SettingsEditAddressState> {
  final DfxKycService _kycService;

  String? _url;

  SettingsEditAddressCubit({required DfxKycService kycService})
    : _kycService = kycService,
      super(const AddressChangeInitial());

  Future<void> startStep() async {
    try {
      emit(const AddressChangeLoading());
      final session = await _kycService.startStep(KycStepName.addressChange);

      if (session.currentStep?.status == KycStepStatus.inReview) {
        emit(const AddressChangePending());
        return;
      }

      _url = session.currentStep?.session.url;
      if (_url == null) throw Exception('No session URL returned');
      emit(AddressChangeReady(_url!));
    } catch (e) {
      emit(AddressChangeFailure(e.toString()));
    }
  }

  void refresh() => startStep();

  Future<void> submitAddress({
    required String street,
    required String houseNumber,
    required String zip,
    required String city,
    required int countryId,
    required String fileBase64,
    required String fileName,
  }) async {
    if (_url == null) return;
    try {
      emit(const AddressChangeSubmitting());
      await _kycService.setData(_url!, {
        'file': fileBase64,
        'fileName': fileName,
        'address': {
          'street': street,
          if (houseNumber.isNotEmpty) 'houseNumber': houseNumber,
          'zip': zip,
          'city': city,
          'country': {'id': countryId},
        },
      });
      emit(const AddressChangeSuccess());
    } catch (e) {
      emit(AddressChangeFailure(e.toString()));
    }
  }
}
