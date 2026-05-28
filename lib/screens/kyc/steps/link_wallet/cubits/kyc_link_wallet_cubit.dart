import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/bitbox_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/dto/real_unit_user_data_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_wallet_service.dart';

part 'kyc_link_wallet_state.dart';

/// Drives the streamlined "Add this wallet" page. Fetches the existing
/// account's user data on construction and, on submit, calls
/// `RealUnitRegistrationService.registerWallet`. Mirror of
/// `KycRegistrationSubmitCubit` for the AddWallet branch — distinct state
/// shape because the page collects no input.
class KycLinkWalletCubit extends Cubit<KycLinkWalletState> {
  final RealUnitWalletService _walletService;
  final RealUnitRegistrationService _registrationService;

  KycLinkWalletCubit(
    RealUnitWalletService walletService,
    RealUnitRegistrationService registrationService,
  ) : _walletService = walletService,
      _registrationService = registrationService,
      super(const KycLinkWalletInitial());

  Future<void> loadUserData() async {
    try {
      emit(const KycLinkWalletLoading());
      final status = await _walletService.getWalletStatus();
      final userData = status.realUnitUserDataDto;
      if (userData == null) {
        emit(const KycLinkWalletFailure('User data not available'));
        return;
      }
      emit(KycLinkWalletReady(userData));
    } catch (e) {
      developer.log(e.toString());
      emit(KycLinkWalletFailure(e.toString(), cause: e));
    }
  }

  Future<void> submit(RealUnitUserDataDto userData) async {
    try {
      emit(KycLinkWalletSubmitting(userData));
      await _registrationService.registerWallet(userData);
      emit(const KycLinkWalletSuccess());
    } on BitboxNotConnectedException catch (e) {
      developer.log(e.toString());
      emit(KycLinkWalletFailure(e.toString(), cause: e));
    } catch (e) {
      developer.log(e.toString());
      emit(KycLinkWalletFailure(e.toString(), cause: e));
    }
  }
}
