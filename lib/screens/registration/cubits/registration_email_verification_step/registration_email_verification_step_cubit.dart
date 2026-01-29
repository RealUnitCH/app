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

    final currentAccountId = await getAccountId();
    _dfxService.invalidateAuthToken();
    final newAccountId = await getAccountId();

    if (currentAccountId != newAccountId) {
      emit(const RegistrationEmailVerificationStepSuccess());
    } else {
      emit(const RegistrationEmailVerificationStepFailure());
    }
  }

  Future<int?> getAccountId() async {
    final token = await _dfxService.getAuthToken();
    if (token == null) return null;
    final currentJwt = JwtDecoder.parseJwt(token);
    return currentJwt['account'] as int?;
  }
}
