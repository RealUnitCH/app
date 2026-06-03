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
import 'package:realunit_wallet/packages/service/dfx/models/payment/pay/dto/lnurlp_payment_dto.dart';
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

  /// Set once the REALU→ZCHF swap has been broadcast successfully. From this
  /// point the user holds ZCHF and recovery must NEVER re-swap — the pay leg is
  /// retried on its own via [retryPay].
  bool _swapCompleted = false;

  /// ZCHF acquired by the (completed) swap — the backend `estimatedAmount` of
  /// the swap quote. Used to detect when a freshly re-fetched settlement amount
  /// can no longer be covered by what we actually hold.
  double _acquiredZchf = 0;

  Timer? _ethPollingTimer;
  Timer? _statusPollingTimer;

  /// Headroom over the OCP ZCHF amount when sizing the swap target. The swap is
  /// quoted/broadcast against the ORIGINAL OCP quote, but the pay step settles
  /// the EXACT amount of a FRESHLY re-fetched quote; in between, the OCP price
  /// (CHF→ZCHF) and the swap rate can both move. A 1% buffer left no margin for
  /// the common case (a few minutes of drift + the OCP/swap fees), so any
  /// adverse move stranded the user in ZCHF that could not cover settlement.
  /// 3% is a pragmatic headroom that absorbs ordinary drift while keeping the
  /// over-swap small (leftover ZCHF simply stays in the wallet); a larger move
  /// is caught explicitly and surfaced as a retryable
  /// [PayRetryReason.insufficientZchf] rather than a server-side failure.
  static const _slippageBuffer = 1.03;

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
    // Environment capability gate — checked BEFORE any on-chain action. The
    // REALU→ZCHF swap is irreversible; if OCP settlement can never succeed on
    // this environment (mainnet-only), refuse here so the user is never swapped
    // into ZCHF and then told "mainnet only". This is environment-static, so it
    // is safe (and required) to evaluate before the swap is signed/broadcast.
    if (!_payService.isPaySupportedEnvironment) {
      emit(const PayProcessFailure(PayProcessFailureReason.payUnsupportedEnvironment));
      return;
    }
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
      // The swap is now irreversible — the user holds ZCHF. From here every
      // recovery path retries the PAY leg only; the swap is never redone.
      _swapCompleted = true;
      _acquiredZchf = swap.estimatedAmount;
      await _refreshQuoteAndPay();
    } on PaySignatureUnsupportedException {
      emit(const PayProcessFailure(PayProcessFailureReason.signatureUnsupported));
    } on BitboxNotConnectedException {
      emit(const PayProcessFailure(PayProcessFailureReason.bitboxRequired));
    } catch (e) {
      emit(PayProcessFailure(PayProcessFailureReason.generic, message: e.toString()));
    }
  }

  /// Retries the pay leg ONLY, after a successful swap. Re-fetches the OCP quote
  /// and re-runs sign + submit; it never re-swaps (guarded by [_swapCompleted]),
  /// so the ZCHF already in the wallet is reused and REALU is never
  /// double-converted. Wired to the retry action on [PayProcessPayRetry].
  Future<void> retryPay() async {
    if (!_swapCompleted) return;
    await _refreshQuoteAndPay();
  }

  /// Re-reads the OCP quote so the pay step uses a fresh quoteId — the swap may
  /// have taken longer than the original quote's validity window. Runs both on
  /// the first pay attempt (right after the swap) and on every [retryPay].
  ///
  /// A GENUINE expiry (the explicit `expiration.isBefore(now)` check) and a
  /// TRANSIENT fetch error are kept distinct: both are recoverable by retrying
  /// the pay leg, so neither forces a re-scan → re-swap.
  Future<void> _refreshQuoteAndPay() async {
    final LnurlpPaymentDto details;
    try {
      emit(const PayProcessRefreshingQuote());
      details = await _payService.getPaymentDetails(_paymentLinkId);
    } catch (e) {
      // Transient/network error fetching the quote — NOT a genuine expiry.
      // Retry the pay leg; the swapped ZCHF stays in the wallet.
      emit(PayProcessPayRetry(PayRetryReason.transient, message: e.toString()));
      return;
    }

    if (details.quote.expiration.isBefore(DateTime.now())) {
      emit(const PayProcessPayRetry(PayRetryReason.quoteExpired));
      return;
    }

    // Guard the slippage boundary: the swap acquired [_acquiredZchf], but the
    // fresh quote may now demand more ZCHF than that. Settling it would fail
    // server-side AFTER the irreversible swap, so surface a typed, retryable
    // state (re-quote may land within the held ZCHF) instead of an opaque
    // failure. The leftover ZCHF stays in the wallet.
    final freshZchf = _zchfTransferAmount(details);
    if (freshZchf != null && freshZchf > _acquiredZchf) {
      emit(
        PayProcessPayRetry(
          PayRetryReason.insufficientZchf,
          message: 'fresh settlement $freshZchf ZCHF exceeds acquired $_acquiredZchf ZCHF',
        ),
      );
      return;
    }

    await _executePay(details.quote.id);
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
    } catch (e) {
      // The swap already happened; the user holds ZCHF. Any pay-leg failure
      // here (signing dropped, BitBox disconnect, transient submit error,
      // settlement rejected) is recoverable by retrying the pay leg — never by
      // re-swapping. Surface the retryable state rather than a terminal failure.
      emit(PayProcessPayRetry(PayRetryReason.transient, message: e.toString()));
    }
  }

  /// The ZCHF amount listed for the Ethereum transfer method in a fresh quote,
  /// or null if the link no longer offers a priced Ethereum/ZCHF method. Mirrors
  /// [PayQuoteCubit]'s selection — the app never computes the amount locally.
  static double? _zchfTransferAmount(LnurlpPaymentDto details) {
    for (final transfer in details.transferAmounts) {
      if (transfer.method.toLowerCase() != 'ethereum') continue;
      for (final asset in transfer.assets) {
        if (asset.asset.toUpperCase() == 'ZCHF') return asset.amount;
      }
    }
    return null;
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
          // The engine reached a terminal non-completed status (e.g. the quote
          // expired or was cancelled before it settled). The user still holds
          // the swapped ZCHF, so this is recoverable by retrying the pay leg.
          emit(const PayProcessPayRetry(PayRetryReason.transient));
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
