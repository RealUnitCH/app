import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/bitbox_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/registration_date_unavailable_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/registration_rejected_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_status.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/dto/real_unit_user_data_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';
import 'package:realunit_wallet/packages/wallet/exceptions/signing_cancelled_exception.dart';
import 'package:realunit_wallet/screens/kyc/steps/update_share_register_name/cubits/kyc_update_share_register_name_state.dart';

/// Signs the approved share-register name via
/// [RealUnitRegistrationService.updateShareRegisterName]. The service owns
/// the signature; this cubit only branches on the result.
class KycUpdateShareRegisterNameCubit extends Cubit<KycUpdateShareRegisterNameState> {
  final RealUnitRegistrationService _registrationService;
  final RealUnitUserDataDto _userData;
  final String _shareRegisterName;

  KycUpdateShareRegisterNameCubit(
    RealUnitRegistrationService registrationService,
    RealUnitUserDataDto userData,
    String shareRegisterName,
  ) : _registrationService = registrationService,
      _userData = userData,
      _shareRegisterName = shareRegisterName,
      super(KycUpdateShareRegisterNameReady(userData, shareRegisterName));

  /// [shareRegisterNameFailed], [shareRegisterNameSendFailed],
  /// [registrationDateUnavailable] and [signingCancelled] are the localized
  /// sentences. The cubit has no `BuildContext`, so the page supplies them.
  Future<void> submit({
    required String shareRegisterNameFailed,
    required String shareRegisterNameSendFailed,
    required String registrationDateUnavailable,
    required String signingCancelled,
  }) async {
    if (isClosed) return;
    if (state is KycUpdateShareRegisterNameSubmitting ||
        state is KycUpdateShareRegisterNameSuccess) {
      return;
    }
    emit(KycUpdateShareRegisterNameSubmitting(_userData, _shareRegisterName));
    try {
      final response = await _registrationService.updateShareRegisterName(
        _userData,
        _shareRegisterName,
      );
      if (isClosed) return;
      switch (response.status) {
        case RegistrationStatus.completed:
        case RegistrationStatus.alreadyRegistered:
        case RegistrationStatus.pendingReview:
          // pendingReview is not a signing error. Success makes the page
          // call checkKyc(); the API then decides the next step.
          emit(const KycUpdateShareRegisterNameSuccess());
        case RegistrationStatus.forwardingFailed:
          // A 202 here means the share register did not accept the update
          // and the stored registration stays. Success would call
          // checkKyc(), reopen this gate, and drop the sentence. Failure
          // returns the button to idle so the user can sign again.
          final rejection = response.rejectionMessage;
          emit(
            KycUpdateShareRegisterNameFailure(rejection ?? shareRegisterNameFailed),
          );
      }
    } on RegistrationDateUnavailableException {
      if (isClosed) return;
      emit(KycUpdateShareRegisterNameFailure(registrationDateUnavailable));
    } on SigningCancelledException {
      if (isClosed) return;
      emit(KycUpdateShareRegisterNameFailure(signingCancelled));
    } on RegistrationRejectedException catch (e) {
      if (isClosed) return;
      emit(
        KycUpdateShareRegisterNameFailure(
          _normalizedErrorMessage(e.message, shareRegisterNameFailed),
        ),
      );
    } on BitboxNotConnectedException {
      if (isClosed) return;
      emit(KycUpdateShareRegisterNameBitboxRequired(_userData, _shareRegisterName));
    } on ApiException catch (e) {
      if (isClosed) return;
      final message = _normalizedErrorMessage(
        ApiException.userFacingMessage(e),
        shareRegisterNameSendFailed,
      );
      emit(KycUpdateShareRegisterNameFailure(message));
    } catch (_) {
      if (isClosed) return;
      emit(KycUpdateShareRegisterNameFailure(shareRegisterNameSendFailed));
    }
  }

  /// Re-runs [submit] after the BitBox was linked from `ConnectBitboxPage`.
  Future<void> retrySubmit({
    required String shareRegisterNameFailed,
    required String shareRegisterNameSendFailed,
    required String registrationDateUnavailable,
    required String signingCancelled,
  }) => submit(
    shareRegisterNameFailed: shareRegisterNameFailed,
    shareRegisterNameSendFailed: shareRegisterNameSendFailed,
    registrationDateUnavailable: registrationDateUnavailable,
    signingCancelled: signingCancelled,
  );

  /// API errors without user-facing text must not render as a blank failure.
  String _normalizedErrorMessage(String message, String fallback) {
    final normalized = message.trim();
    if (normalized.isEmpty || normalized == 'Unknown error') return fallback;
    return normalized;
  }
}
