import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/bitbox_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/payment/transfer_exceptions.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/transfer/dto/real_unit_transfer_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_transfer_service.dart';
import 'package:realunit_wallet/packages/wallet/exceptions/signing_cancelled_exception.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';

part 'send_process_state.dart';

/// Orchestrates the gasless wallet-to-wallet transfer once the user confirms:
/// gate the wallet's signing capability → `PUT /transfer` (prepare + EIP-7702
/// delegation data) → sign the EIP-712 delegation + EIP-7702 authorization and
/// `PUT /transfer/:id/confirm` → success (txHash) / a typed failure.
///
/// The gasless EIP-7702 path can only be signed by a software wallet today;
/// debug and BitBox wallets are gated up-front (the contract's capability gate —
/// the flow is NOT otherwise branched on wallet type). Insufficient REALU and
/// invalid-address are decided by the API and rendered from its signal; a 503
/// (gas-funding-unavailable) surfaces as a dedicated "temporarily unavailable"
/// state.
class SendProcessCubit extends Cubit<SendProcessState> {
  final RealUnitTransferService _transferService;
  final AppStore _appStore;
  final String _recipient;
  final int _amount;

  SendProcessCubit({
    required RealUnitTransferService transferService,
    required AppStore appStore,
    required String recipient,
    required int amount,
  }) : _transferService = transferService,
       _appStore = appStore,
       _recipient = recipient,
       _amount = amount,
       super(const SendProcessInitial());

  /// Entry point — called by the view once the user confirms the summary.
  Future<void> start() async {
    // Capability gate BEFORE any network/sign action: only a software wallet can
    // produce the EIP-712 delegation + EIP-7702 authorization the gasless
    // transfer requires. Surface the dedicated unsupported state otherwise.
    if (_appStore.wallet.walletType != WalletType.software) {
      emit(const SendProcessFailure(SendProcessFailureReason.signatureUnsupported));
      return;
    }

    try {
      emit(const SendProcessPreparing());
      final info = await _transferService.prepareTransfer(
        RealUnitTransferDto(toAddress: _recipient, amount: _amount),
      );

      emit(const SendProcessSigning());
      final txHash = await _transferService.confirmTransfer(info);

      emit(SendProcessSuccess(txHash));
    } on TransferSignatureUnsupportedException {
      emit(const SendProcessFailure(SendProcessFailureReason.signatureUnsupported));
    } on TransferGasFundingUnavailableException {
      emit(const SendProcessFailure(SendProcessFailureReason.gasFundingUnavailable));
    } on SigningCancelledException {
      emit(const SendProcessFailure(SendProcessFailureReason.signatureCancelled));
    } on BitboxNotConnectedException {
      emit(const SendProcessFailure(SendProcessFailureReason.signatureUnsupported));
    } on ApiException catch (e) {
      // The API is the authority on recipient/amount/eligibility. Render its
      // signaled reason rather than re-deriving limits locally.
      emit(SendProcessFailure(_reasonForApi(e), message: e.message));
    } catch (e) {
      emit(SendProcessFailure(SendProcessFailureReason.generic, message: e.toString()));
    }
  }

  /// Maps an API error to a typed failure reason. A 400 from `PUT /transfer`
  /// covers both an invalid recipient and insufficient REALU; both render a
  /// generic "could not prepare the transfer" message keyed off the API text,
  /// so they share [SendProcessFailureReason.invalidRequest].
  static SendProcessFailureReason _reasonForApi(ApiException e) {
    if (e.statusCode == 503) return SendProcessFailureReason.gasFundingUnavailable;
    if (e.statusCode == 400 || e.statusCode == 404) {
      return SendProcessFailureReason.invalidRequest;
    }
    return SendProcessFailureReason.generic;
  }
}
