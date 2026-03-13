import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_level.dart';

part 'settings_edit_name_state.dart';

class SettingsEditNameCubit extends Cubit<SettingsEditNameState> {
  final DfxKycService _kycService;

  String? _url;

  SettingsEditNameCubit({required DfxKycService kycService})
    : _kycService = kycService,
      super(const SettingsEditNameInitial()) {
    _loadEdit();
  }

  Future<void> _loadEdit() async {
    try {
      emit(const SettingsEditNameLoading());
      final session = await _kycService.startStep(KycStepName.nameChange);

      if (session.currentStep?.status == KycStepStatus.inReview) {
        emit(const SettingsEditNamePending());
        return;
      }

      _url = session.currentStep?.session.url;
      if (_url == null) throw Exception('No session URL returned');
      emit(SettingsEditNameReady(_url!));
    } catch (e) {
      emit(SettingsEditNameFailure(e.toString()));
    }
  }

  void refresh() => _loadEdit();

  Future<void> submitName({
    required String firstName,
    required String lastName,
    required String fileBase64,
    required String fileName,
  }) async {
    if (_url == null) return;
    try {
      emit(const SettingsEditNameSubmitting());
      await _kycService.setData(_url!, {
        'firstName': firstName,
        'lastName': lastName,
        'file': fileBase64,
        'fileName': fileName,
      });
      emit(const SettingsEditNameSuccess());
    } catch (e) {
      emit(SettingsEditNameFailure(e.toString()));
    }
  }
}
