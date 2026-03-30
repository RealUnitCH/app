import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_auth_service.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_wallet_service.dart';
import 'package:realunit_wallet/packages/utils/jwt_decoder.dart';

part 'kyc_email_verification_state.dart';

class KycEmailVerificationCubit extends Cubit<KycEmailVerificationState> {
  final DFXAuthService _dfxService;
  final RealUnitWalletService _walletService;
  final RealUnitRegistrationService _registrationService;

  KycEmailVerificationCubit({
    required DFXAuthService dfxService,
    required RealUnitWalletService walletService,
    required RealUnitRegistrationService registrationService,
  }) : _dfxService = dfxService,
       _walletService = walletService,
       _registrationService = registrationService,
       super(const KycEmailVerificationInitial());

  Future<void> checkEmailVerification() async {
    emit(const KycEmailVerificationLoading());

    final currentAccountId = await getAccountId();
    _dfxService.invalidateAuthToken();
    final newAccountId = await getAccountId();

    if (currentAccountId != newAccountId) {
      await _completeRegistration();
      emit(const KycEmailVerificationSuccess());
    } else {
      emit(const KycEmailVerificationFailure());
    }
  }

  Future<void> _completeRegistration() async {
    try {
      final status = await _walletService.getWalletStatus();
      if (status.realUnitUserDataDto == null) throw Exception('No existing user data');
      await _registrationService.registerWallet(status.realUnitUserDataDto!);
    } catch (e) {
      developer.log(e.toString());
      emit(const KycEmailVerificationRegistrationFailure());
    }
  }

  Future<int?> getAccountId() async {
    final token = await _dfxService.getAuthToken();
    if (token == null) return null;
    final currentJwt = JwtDecoder.parseJwt(token);
    return currentJwt['account'] as int?;
  }
}
