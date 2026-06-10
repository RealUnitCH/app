import 'package:realunit_wallet/packages/service/dfx/exceptions/bitbox_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_status.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/dto/real_unit_user_data_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';

/// Overrides [RealUnitRegistrationService.registerWallet] so the first call
/// throws [BitboxNotConnectedException] — exactly the scenario the KYC
/// link-wallet connect sheet guards against (bug fix PR #720).
///
/// Subsequent calls delegate to the real service. The state resets when the
/// app process restarts, matching the Maestro handbook flow lifecycle.
class MaestroRegistrationService extends RealUnitRegistrationService {
  MaestroRegistrationService(super.appStore, super.walletService);

  bool _firstCall = true;

  @override
  Future<RegistrationStatus> registerWallet(
    RealUnitUserDataDto userData,
  ) async {
    if (_firstCall) {
      _firstCall = false;
      throw const BitboxNotConnectedException();
    }
    return super.registerWallet(userData);
  }
}
