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

  // `Future.timeout` does not cancel the underlying work, so a late HTTP
  // response from an earlier call can still resume after a retry. Each
  // `checkEmailVerification` captures its own generation; any continuation
  // bails when its generation no longer matches the current one. Acts as a
  // cancellation token for non-cancellable HTTP work, and lets a fast
  // double-tap supersede the in-flight call instead of racing two emit
  // sequences. Pattern mirrors `KycCubit._runGeneration`.
  int _runGeneration = 0;

  // Once the JWT account-id change has confirmed the merge, the auth side
  // is settled — re-running the account-id comparison on a retry would just
  // emit `Failure` ("email not yet confirmed") because `getAuthToken` keeps
  // returning the new (merged) account. The remaining work that can still
  // race is `getWalletStatus` propagation on the user-data side, so a retry
  // after a `RegistrationFailure` should skip the auth-side check and go
  // straight to `_completeRegistration`.
  bool _mergeDetected = false;

  KycEmailVerificationCubit({
    required DFXAuthService dfxService,
    required RealUnitWalletService walletService,
    required RealUnitRegistrationService registrationService,
  }) : _dfxService = dfxService,
       _walletService = walletService,
       _registrationService = registrationService,
       super(const KycEmailVerificationInitial());

  Future<void> checkEmailVerification() async {
    final generation = ++_runGeneration;
    if (isClosed) return;
    emit(const KycEmailVerificationLoading());

    if (!_mergeDetected) {
      final currentAccountId = await getAccountId();
      if (isClosed || generation != _runGeneration) return;
      _dfxService.invalidateAuthToken();
      final newAccountId = await getAccountId();
      if (isClosed || generation != _runGeneration) return;

      if (currentAccountId == newAccountId) {
        // Email link not yet clicked, or token still cached. The user can
        // retry by tapping again once the link in the confirmation mail has
        // actually been visited.
        emit(const KycEmailVerificationFailure());
        return;
      }
      _mergeDetected = true;
    }

    // JWT account changed → backend recognised the merge. Now associate the
    // new wallet with the merged user via the EIP-712 registration signature.
    if (await _completeRegistration(generation)) {
      if (isClosed || generation != _runGeneration) return;
      emit(const KycEmailVerificationSuccess());
    }
    // else: _completeRegistration already emitted RegistrationFailure; we
    // intentionally do NOT emit Success here so the verification page stays
    // open and the user can retry without the failure being papered over.
  }

  /// Returns `true` when the wallet was successfully registered with the
  /// (now-merged) user account. On failure the cubit is already in
  /// [KycEmailVerificationRegistrationFailure] so the listener can show the
  /// error to the user.
  Future<bool> _completeRegistration(int generation) async {
    try {
      final status = await _walletService.getWalletStatus();
      if (isClosed || generation != _runGeneration) return false;
      if (status.realUnitUserDataDto == null) {
        // Backend race: the auth service reports the merged account while the
        // user-data service hasn't propagated yet. Surface as a recoverable
        // failure so the user can retry by tapping the confirmation button
        // again — by then propagation will usually have completed, and the
        // retry path skips the auth-side check thanks to `_mergeDetected`.
        developer.log(
          'getWalletStatus returned null realUnitUserDataDto after merge',
        );
        emit(const KycEmailVerificationRegistrationFailure());
        return false;
      }
      await _registrationService.registerWallet(status.realUnitUserDataDto!);
      if (isClosed || generation != _runGeneration) return false;
      return true;
    } catch (e) {
      if (isClosed || generation != _runGeneration) return false;
      developer.log('registerWallet failed: $e');
      emit(const KycEmailVerificationRegistrationFailure());
      return false;
    }
  }

  Future<int?> getAccountId() async {
    final token = await _dfxService.getAuthToken();
    if (token == null) return null;
    final currentJwt = JwtDecoder.parseJwt(token);
    return currentJwt['account'] as int?;
  }
}
