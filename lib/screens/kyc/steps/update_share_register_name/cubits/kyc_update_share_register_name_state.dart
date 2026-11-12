import 'package:equatable/equatable.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/dto/real_unit_user_data_dto.dart';

abstract class KycUpdateShareRegisterNameState extends Equatable {
  const KycUpdateShareRegisterNameState();

  @override
  List<Object?> get props => [];
}

class KycUpdateShareRegisterNameReady extends KycUpdateShareRegisterNameState {
  final RealUnitUserDataDto userData;
  final String shareRegisterName;

  const KycUpdateShareRegisterNameReady(this.userData, this.shareRegisterName);

  @override
  List<Object?> get props => [userData, shareRegisterName];
}

class KycUpdateShareRegisterNameSubmitting extends KycUpdateShareRegisterNameState {
  final RealUnitUserDataDto userData;
  final String shareRegisterName;

  const KycUpdateShareRegisterNameSubmitting(this.userData, this.shareRegisterName);

  @override
  List<Object?> get props => [userData, shareRegisterName];
}

class KycUpdateShareRegisterNameSuccess extends KycUpdateShareRegisterNameState {
  const KycUpdateShareRegisterNameSuccess();
}

/// [message] is the sentence the page shows. The cubit chooses it: the
/// rejection sentence, or the localized signing / date / generic copy the
/// page passed into `submit`.
class KycUpdateShareRegisterNameFailure extends KycUpdateShareRegisterNameState {
  final String message;

  const KycUpdateShareRegisterNameFailure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Signing stopped because the BitBox is not connected. Not a rejection:
/// the page opens `ConnectBitboxPage` and calls `retrySubmit` once the
/// device is linked. The signing page stays visible under the sheet.
class KycUpdateShareRegisterNameBitboxRequired extends KycUpdateShareRegisterNameState {
  final RealUnitUserDataDto userData;
  final String shareRegisterName;

  const KycUpdateShareRegisterNameBitboxRequired(this.userData, this.shareRegisterName);

  @override
  List<Object?> get props => [userData, shareRegisterName];
}
