import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/payment/pay_exceptions.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/payment/sell_exceptions.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/pay/swap_payment_info.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_pay_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/screens/transaction_history/completed_transaction.dart';

part 'pay_process_state.dart';

/// Software-wallet pay. The customer only signs the EIP-7702 delegation. The
/// DFX relayer broadcasts one transaction and pays gas from the DFX balance,
/// the same way as sell. There is no faucet and no user-signed transfer.
///
/// Only the software wallet is offered pay. Any other wallet, including
/// BitBox and the debug wallet, ends as [PayProcessNotOffered] and never
/// asks the relayer. A confirm that never left the device leaves the quote
/// reusable. A confirm that may already have been relayed ends as a
/// failure, and this payment is not sent again.
class PayProcessCubit extends Cubit<PayProcessState> {
  final RealUnitPayService _payService;
  final AppStore _appStore;

  final String _paymentLinkId;
  final String _quoteId;
  final SwapPaymentInfo _swap;

  bool _confirmSent = false;

  bool get swapCompleted => _confirmSent;

  Timer? _statusPollingTimer;

  static const _statusPollMaxAttempts = 40;
  static const _statusPollInterval = Duration(seconds: 3);

  int _statusPollGeneration = 0;
  int _statusPollAttempts = 0;
  bool _statusPollInFlight = false;

  PayProcessCubit({
    required RealUnitPayService payService,
    required AppStore appStore,
    required String paymentLinkId,
    required String quoteId,
    required SwapPaymentInfo swap,
  }) : _payService = payService,
       _appStore = appStore,
       _paymentLinkId = paymentLinkId,
       _quoteId = quoteId,
       _swap = swap,
       super(const PayProcessInitial());

  Future<void> start() async {
    final walletType = _appStore.wallet.walletType;
    if (walletType != WalletType.software) {
      emit(const PayProcessNotOffered());
      return;
    }
    if (!_swap.isValid) {
      final error = _swap.error;
      emit(
        PayProcessFailure(
          PayProcessFailureReason.generic,
          message: (error != null && error.isNotEmpty) ? error : null,
        ),
      );
      return;
    }
    if (_swap.eip7702 == null) {
      emit(const PayProcessFailure(PayProcessFailureReason.generic));
      return;
    }
    await _relay();
  }

  Future<void> _relay() async {
    emit(const PayProcessPaying());
    try {
      final txHash = await _payService.confirmOcpPay(
        swap: _swap,
        paymentLinkId: _paymentLinkId,
        quoteId: _quoteId,
      );
      if (isClosed) return;
      _confirmSent = true;
      emit(PayProcessAwaitingSettlement(txHash));
      _startStatusPolling();
    } on AlreadyConfirmedException {
      if (isClosed) return;
      _confirmSent = true;
      emit(const PayProcessAwaitingSettlement('confirmed'));
      _startStatusPolling();
    } on PayConfirmNotSubmittedException catch (e) {
      if (isClosed) return;
      emit(
        PayProcessFailure(
          PayProcessFailureReason.generic,
          message: e.apiMessage,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      _confirmSent = true;
      emit(
        PayProcessFailure(
          PayProcessFailureReason.generic,
          message: e is ApiException ? e.message : null,
        ),
      );
    }
  }

  void _startStatusPolling() {
    _statusPollingTimer?.cancel();
    final generation = ++_statusPollGeneration;
    _statusPollAttempts = 0;
    _statusPollInFlight = false;
    _statusPollingTimer = Timer.periodic(_statusPollInterval, (_) async {
      if (generation != _statusPollGeneration || _statusPollInFlight) return;
      _statusPollInFlight = true;
      try {
        final status = await _payService.getPayStatus(_paymentLinkId);
        if (isClosed || generation != _statusPollGeneration) return;
        _statusPollAttempts++;
        if (!status.status.isTerminal) {
          if (_statusPollAttempts >= _statusPollMaxAttempts) {
            _statusPollingTimer?.cancel();
            emit(const PayProcessFailure(PayProcessFailureReason.generic));
            return;
          }
          _statusPollInFlight = false;
          return;
        }
        _statusPollingTimer?.cancel();
        if (status.status.isCompleted) {
          final awaiting = state;
          final rawTxId = awaiting is PayProcessAwaitingSettlement
              ? awaiting.txId
              : null;
          emit(
            PayProcessSuccess(
              txHash: usableTxHash(rawTxId),
              shareAmount: _swap.amount.round(),
            ),
          );
        } else {
          emit(const PayProcessFailure(PayProcessFailureReason.generic));
        }
      } catch (_) {
        if (isClosed || generation != _statusPollGeneration) return;
        _statusPollAttempts++;
        if (_statusPollAttempts >= _statusPollMaxAttempts) {
          _statusPollingTimer?.cancel();
          emit(const PayProcessFailure(PayProcessFailureReason.generic));
          return;
        }
        _statusPollInFlight = false;
      }
    });
  }

  @override
  Future<void> close() {
    _statusPollingTimer?.cancel();
    return super.close();
  }
}
