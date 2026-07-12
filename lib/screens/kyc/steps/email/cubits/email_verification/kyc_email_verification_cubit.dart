import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_auth_service.dart';
import 'package:realunit_wallet/packages/utils/jwt_decoder.dart';

part 'kyc_email_verification_state.dart';

class KycEmailVerificationCubit extends Cubit<KycEmailVerificationState> {
  final DFXAuthService _dfxService;

  // `Future.timeout` does not cancel the underlying work, so a late HTTP
  // response from an earlier call can still resume after a retry. Each
  // `checkEmailVerification` captures its own generation; any continuation
  // bails when its generation no longer matches the current one. Acts as a
  // cancellation token for non-cancellable HTTP work, and lets a fast
  // double-tap supersede the in-flight call instead of racing two emit
  // sequences. Pattern mirrors `KycCubit._runGeneration`.
  int _runGeneration = 0;

  KycEmailVerificationCubit({required DFXAuthService dfxService})
    : _dfxService = dfxService,
      super(const KycEmailVerificationInitial());

  /// Confirms the account merge by detecting that the backend re-issued the JWT
  /// for the merged (master) account. Registration is intentionally NOT done
  /// here: once the merge is confirmed, the KYC flow (`KycCubit`) is the single
  /// source of truth for what this wallet needs next — add wallet vs. full
  /// registration — see CONTRIBUTING.md "API as Decision Authority". The page
  /// pops on [KycEmailVerificationSuccess] and `KycEmailPage` re-runs `checkKyc`.
  Future<void> checkEmailVerification() async {
    final generation = ++_runGeneration;
    if (isClosed) return;
    emit(const KycEmailVerificationLoading());

    final currentAccountId = await getAccountId();
    if (isClosed || generation != _runGeneration) return;
    _dfxService.invalidateAuthToken();
    final newAccountId = await getAccountId();
    if (isClosed || generation != _runGeneration) return;

    if (currentAccountId == newAccountId) {
      // Email link not yet clicked, or token still cached. The user can retry
      // by tapping again once the link in the confirmation mail has been visited.
      emit(const KycEmailVerificationFailure());
      return;
    }

    // JWT account changed → the backend recognised the merge. Hand back to the
    // KYC flow, which routes the wallet to add-wallet or full registration.
    emit(const KycEmailVerificationSuccess());
  }

  Future<int?> getAccountId() async {
    final token = await _dfxService.getAuthToken();
    if (token == null) return null;
    final currentJwt = JwtDecoder.parseJwt(token);
    return currentJwt['account'] as int?;
  }
}
