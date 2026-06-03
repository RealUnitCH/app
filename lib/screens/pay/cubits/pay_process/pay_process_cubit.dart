import 'dart:async';
import 'dart:typed_data';

import 'package:convert/convert.dart' as convert;
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_blockchain_api_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_faucet_service.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/bitbox_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/payment/pay_exceptions.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/pay/dto/real_unit_ocp_pay_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/pay/dto/real_unit_ocp_pay_submit_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/pay/dto/real_unit_ocp_pay_unsigned_transaction_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/pay/dto/real_unit_swap_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/pay/swap_payment_info.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/broadcast_transaction_request_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_pay_service.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:web3dart/crypto.dart';

part 'pay_process_state.dart';

/// Orchestrates the on-chain half of the OCP pay flow after the user confirms a
/// quote: check ETH gas → swap REALU→ZCHF (sign + broadcast) → re-fetch the OCP
/// quote (fresh quoteId, guards expiry between swap and pay) → pay (sign +
/// submit) → poll status until terminal.
///
/// Signing uses the unified raw-payload path (`signToSignature` → r/s/v) for
/// BOTH software and BitBox wallets — the backend returns the unsigned txs, the
/// app signs them the same way regardless of wallet mode. The flow is NOT
/// branched on `walletType`; only the genuine capability gap (a debug wallet
/// that cannot sign) is gated, surfacing [PaySignaturePending] →
/// [PaySignatureUnsupportedException].
class PayProcessCubit extends Cubit<PayProcessState> {
  final RealUnitPayService _payService;
  final DfxFaucetService _faucetService;
  final DfxBlockchainApiService _blockchainService;
  final WalletService _walletService;
  final AppStore _appStore;

  final String _paymentLinkId;
  final double _zchfNeeded;

  SwapPaymentInfo? _swap;

  Timer? _ethPollingTimer;
  Timer? _statusPollingTimer;

  /// Small buffer over the OCP ZCHF amount so the swap target covers the OCP
  /// fee/min-fee and price slippage between quoting and settling.
  static const _slippageBuffer = 1.01;

  static const _ethPollInterval = Duration(seconds: 5);
  static const _statusPollInterval = Duration(seconds: 3);

  PayProcessCubit({
    required RealUnitPayService payService,
    required DfxFaucetService faucetService,
    required DfxBlockchainApiService blockchainService,
    required WalletService walletService,
    required AppStore appStore,
    required String paymentLinkId,
    required double zchfNeeded,
  }) : _payService = payService,
       _faucetService = faucetService,
       _blockchainService = blockchainService,
       _walletService = walletService,
       _appStore = appStore,
       _paymentLinkId = paymentLinkId,
       _zchfNeeded = zchfNeeded,
       super(const PayProcessInitial());

  /// Entry point — called by the view once the user confirms the quote.
  Future<void> start() async {
    if (_appStore.wallet.walletType == WalletType.debug) {
      emit(const PayProcessFailure(PayProcessFailureReason.signatureUnsupported));
      return;
    }
    await _requestSwapQuote();
  }

  Future<void> _requestSwapQuote() async {
    try {
      emit(const PayProcessPreparingSwap());
      final swap = await _payService.getSwapPaymentInfo(
        RealUnitSwapDto.fromTargetAmount(_zchfNeeded * _slippageBuffer),
      );
      _swap = swap;

      // The API is the authority on whether the swap is fundable; render its
      // signal rather than recomputing limits locally.
      if (!swap.isValid) {
        emit(const PayProcessFailure(PayProcessFailureReason.insufficientZchf));
        return;
      }

      await _checkEthBalance(swap);
    } catch (e) {
      emit(PayProcessFailure(PayProcessFailureReason.generic, message: e.toString()));
    }
  }

  Future<void> _checkEthBalance(SwapPaymentInfo swap) async {
    if (swap.ethBalance >= swap.requiredGasEth) {
      await _executeSwap();
      return;
    }
    await _requestFaucet(swap);
  }

  Future<void> _requestFaucet(SwapPaymentInfo swap) async {
    try {
      emit(const PayProcessWaitingForEth());
      await _faucetService.requestFaucet();
      _startEthPolling(swap);
    } catch (e) {
      emit(PayProcessFailure(PayProcessFailureReason.insufficientEth, message: e.toString()));
    }
  }

  void _startEthPolling(SwapPaymentInfo swap) {
    _ethPollingTimer?.cancel();
    _ethPollingTimer = Timer.periodic(_ethPollInterval, (_) async {
      try {
        final balance = await _blockchainService.getEthBalance(_appStore.primaryAddress);
        if (balance >= swap.requiredGasEth) {
          _ethPollingTimer?.cancel();
          await _executeSwap();
        }
      } catch (_) {
        // keep polling on transient errors
      }
    });
  }

  Future<void> _executeSwap() async {
    final swap = _swap;
    if (swap == null) return;
    try {
      emit(const PayProcessSwapping());
      final unsigned = await _payService.createSwapUnsignedTransaction(swap.id);
      final signed = await _signTransaction(unsigned.swap);
      await _payService.broadcastSwapTransaction(swap.id, signed);
      await _refreshQuoteAndPay();
    } on PaySignatureUnsupportedException {
      emit(const PayProcessFailure(PayProcessFailureReason.signatureUnsupported));
    } on BitboxNotConnectedException {
      emit(const PayProcessFailure(PayProcessFailureReason.bitboxRequired));
    } catch (e) {
      emit(PayProcessFailure(PayProcessFailureReason.generic, message: e.toString()));
    }
  }

  /// Re-reads the OCP quote so the pay step uses a fresh quoteId — the swap may
  /// have taken longer than the original quote's validity window.
  Future<void> _refreshQuoteAndPay() async {
    try {
      emit(const PayProcessRefreshingQuote());
      final details = await _payService.getPaymentDetails(_paymentLinkId);
      if (details.quote.expiration.isBefore(DateTime.now())) {
        emit(const PayProcessFailure(PayProcessFailureReason.quoteExpired));
        return;
      }
      await _executePay(details.quote.id);
    } catch (e) {
      emit(PayProcessFailure(PayProcessFailureReason.quoteExpired, message: e.toString()));
    }
  }

  Future<void> _executePay(String quoteId) async {
    try {
      emit(const PayProcessPaying());
      final RealUnitOcpPayUnsignedTransactionDto unsigned = await _payService
          .createPayUnsignedTransaction(
            RealUnitOcpPayDto(paymentLinkId: _paymentLinkId, quoteId: quoteId),
          );
      final signed = await _signTransaction(unsigned.unsignedTx);
      final txId = await _payService.submitPay(
        RealUnitOcpPaySubmitDto(
          unsignedTx: signed.unsignedTx,
          r: signed.r,
          s: signed.s,
          v: signed.v,
          paymentLinkId: _paymentLinkId,
          quoteId: quoteId,
        ),
      );
      emit(PayProcessAwaitingSettlement(txId));
      _startStatusPolling();
    } on PayUnsupportedEnvironmentException {
      emit(const PayProcessFailure(PayProcessFailureReason.payUnsupportedEnvironment));
    } on PaySignatureUnsupportedException {
      emit(const PayProcessFailure(PayProcessFailureReason.signatureUnsupported));
    } on BitboxNotConnectedException {
      emit(const PayProcessFailure(PayProcessFailureReason.bitboxRequired));
    } catch (e) {
      emit(PayProcessFailure(PayProcessFailureReason.payFailed, message: e.toString()));
    }
  }

  void _startStatusPolling() {
    _statusPollingTimer?.cancel();
    _statusPollingTimer = Timer.periodic(_statusPollInterval, (_) async {
      try {
        final status = await _payService.getPayStatus(_paymentLinkId);
        if (!status.status.isTerminal) return;
        _statusPollingTimer?.cancel();
        if (status.status.isCompleted) {
          emit(const PayProcessSuccess());
        } else {
          emit(const PayProcessFailure(PayProcessFailureReason.payFailed));
        }
      } catch (_) {
        // keep polling on transient errors
      }
    });
  }

  /// Signs a serialized unsigned EIP-1559 tx with the active wallet credentials
  /// and returns the broadcast envelope (`unsignedTx` + r/s/v). Works for
  /// software and BitBox; a debug wallet's `signToSignature` throws
  /// [UnsupportedError], normalised here to [PaySignatureUnsupportedException].
  Future<BroadcastTransactionRequestDto> _signTransaction(String rawTransaction) async {
    await _walletService.ensureCurrentWalletUnlocked();
    try {
      final credentials = _appStore.wallet.currentAccount.primaryAddress;
      final payload = Uint8List.fromList(
        convert.hex.decode(
          rawTransaction.startsWith('0x') ? rawTransaction.substring(2) : rawTransaction,
        ),
      );
      final MsgSignature sig;
      try {
        sig = await credentials.signToSignature(
          payload,
          chainId: _appStore.apiConfig.asset.chainId,
          isEIP1559: true,
        );
      } on UnsupportedError {
        throw const PaySignatureUnsupportedException();
      }
      final r = sig.r.toRadixString(16).padLeft(64, '0');
      final s = sig.s.toRadixString(16).padLeft(64, '0');
      return BroadcastTransactionRequestDto(
        unsignedTx: rawTransaction,
        r: '0x$r',
        s: '0x$s',
        v: sig.v,
      );
    } finally {
      await _walletService.lockCurrentWallet();
    }
  }

  @override
  Future<void> close() {
    _ethPollingTimer?.cancel();
    _statusPollingTimer?.cancel();
    return super.close();
  }
}
