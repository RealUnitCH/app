import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/bitbox_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/dto/real_unit_user_data_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';

part 'kyc_link_wallet_state.dart';

/// Drives the streamlined "Add this wallet" page. The userData is supplied by
/// the parent `KycCubit` (which already fetched it via `getRegistrationInfo()` as
/// part of its routing decision) — this cubit never re-fetches. On submit,
/// calls `RealUnitRegistrationService.registerWallet`. Parallel to
/// `KycRegisterCubit` for the AddWallet branch — distinct because the wire
/// call is `/register/wallet` instead of `/register/complete`.
class KycLinkWalletCubit extends Cubit<KycLinkWalletState> {
  final RealUnitRegistrationService _registrationService;

  KycLinkWalletCubit(
    RealUnitRegistrationService registrationService,
    RealUnitUserDataDto userData,
  ) : _registrationService = registrationService,
      super(KycLinkWalletReady(userData));

  Future<void> submit(RealUnitUserDataDto userData) async {
    try {
      emit(KycLinkWalletSubmitting(userData));
      await _registrationService.registerWallet(userData);
      emit(const KycLinkWalletSuccess());
    } on BitboxNotConnectedException catch (e) {
      // TODO(realunit): mirror the reconnect-sheet recovery from
      // kyc_register_cubit.dart — emit a dedicated `KycLinkWalletBitboxRequired`
      // state and surface `showBitboxReconnectSheet` from the page so a
      // transient BLE drop doesn't force the user to restart the wallet-link
      // ceremony. Out of scope for the registration-page review follow-up.
      emit(KycLinkWalletFailure(e.toString(), cause: e));
    } catch (e) {
      emit(KycLinkWalletFailure(e.toString(), cause: e));
    }
  }
}
