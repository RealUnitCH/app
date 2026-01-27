import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_auth_service.dart';
import 'package:realunit_wallet/packages/utils/jwt_decoder.dart';

part 'registration_email_verification_step_state.dart';

class RegistrationEmailVerificationStepCubit extends Cubit<RegistrationEmailVerificationStepState> {
  final DFXAuthService _dfxService;

  RegistrationEmailVerificationStepCubit({required DFXAuthService dfxService})
      : _dfxService = dfxService,
        super(const RegistrationEmailVerificationStepInitial());

  Future<void> checkEmailVerification() async {
    emit(const RegistrationEmailVerificationStepLoading());

    final currentToken = await _dfxService.getAuthToken();
    if (currentToken == null) return;
    final currentJwt = JwtDecoder.parseJwt(currentToken);

    _dfxService.invalidateAuthToken();
    final newToken = await _dfxService.getAuthToken();
    if (newToken == null) return;
    final newJwt = JwtDecoder.parseJwt(currentToken);

    if (currentJwt['account'] as int != newJwt['account'] as int) {
      emit(const RegistrationEmailVerificationStepSuccess());
    } else {
      emit(const RegistrationEmailVerificationStepFailure());
    }
  }
}
