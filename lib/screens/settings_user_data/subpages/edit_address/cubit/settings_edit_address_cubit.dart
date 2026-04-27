import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/tfa_required_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_level.dart';

part 'settings_edit_address_state.dart';

class SettingsEditAddressCubit extends Cubit<SettingsEditAddressState> {
  final DfxKycService _kycService;

  SettingsEditAddressCubit({required DfxKycService kycService})
    : _kycService = kycService,
      super(const SettingsEditAddressInitial()) {
    _loadEdit();
  }

  Future<void> _loadEdit() async {
    try {
      emit(const SettingsEditAddressLoading());
      final session = await _kycService.startStep(KycStepName.addressChange);

      if (session.currentStep?.status == KycStepStatus.inReview) {
        emit(const SettingsEditAddressPending());
        return;
      }

      final url = session.currentStep?.session.url;
      if (url == null) throw Exception('No session URL returned');
      emit(SettingsEditAddressReady(url));
    } on TfaRequiredException {
      emit(const SettingsEditAddressRequiresTfa());
    } catch (e) {
      emit(SettingsEditAddressFailure(e.toString()));
    }
  }

  void refresh() => _loadEdit();

  Future<void> submitAddress({
    required String street,
    required String houseNumber,
    required String zip,
    required String city,
    required int countryId,
    required String fileBase64,
    required String fileName,
  }) async {
    final currentState = state;
    if (currentState is! SettingsEditAddressReady) return;

    final url = currentState.url;
    try {
      emit(SettingsEditAddressSubmitting(url));
      await _kycService.setData(url, {
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
      emit(const SettingsEditAddressSuccess());
    } catch (e) {
      emit(SettingsEditAddressFailure(e.toString()));
    }
  }
}
