import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_auth_service.dart';
import 'package:realunit_wallet/packages/utils/jwt_decoder.dart';

part 'kyc_registration_email_verification_state.dart';

class KycRegistrationEmailVerificationCubit extends Cubit<KycRegistrationEmailVerificationState> {
  final DFXAuthService _dfxService;

  KycRegistrationEmailVerificationCubit({required DFXAuthService dfxService})
      : _dfxService = dfxService,
        super(const KycRegistrationEmailVerificationInitial());

  Future<void> checkEmailVerification() async {
    emit(const KycRegistrationEmailVerificationLoading());

    final currentAccountId = await getAccountId();
    _dfxService.invalidateAuthToken();
    final newAccountId = await getAccountId();

    if (currentAccountId != newAccountId) {
      emit(const KycRegistrationEmailVerificationSuccess());
    } else {
      emit(const KycRegistrationEmailVerificationFailure());
    }
  }

  Future<int?> getAccountId() async {
    final token = await _dfxService.getAuthToken();
    if (token == null) return null;
    final currentJwt = JwtDecoder.parseJwt(token);
    return currentJwt['account'] as int?;
  }
}
