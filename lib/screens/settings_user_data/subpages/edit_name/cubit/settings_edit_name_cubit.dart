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
      super(const NameChangeInitial());

  Future<void> startStep() async {
    try {
      emit(const NameChangeLoading());
      final session = await _kycService.startStep(KycStepName.nameChange);

      if (session.currentStep?.status == KycStepStatus.inReview) {
        emit(const NameChangePending());
        return;
      }

      _url = session.currentStep?.session.url;
      if (_url == null) throw Exception('No session URL returned');
      emit(NameChangeReady(_url!));
    } catch (e) {
      emit(NameChangeFailure(e.toString()));
    }
  }

  void refresh() => startStep();

  Future<void> submitName({
    required String firstName,
    required String lastName,
    required String fileBase64,
    required String fileName,
  }) async {
    if (_url == null) return;
    try {
      emit(const NameChangeSubmitting());
      await _kycService.setData(_url!, {
        'firstName': firstName,
        'lastName': lastName,
        'file': fileBase64,
        'fileName': fileName,
      });
      emit(const NameChangeSuccess());
    } catch (e) {
      emit(NameChangeFailure(e.toString()));
    }
  }
}
