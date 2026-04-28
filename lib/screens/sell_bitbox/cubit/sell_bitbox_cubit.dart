import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart' as convert;
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox_credentials.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_blockchain_api_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_faucet_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/sell_payment_info.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_sell_payment_info_service.dart';

part 'sell_bitbox_state.dart';

class SellBitboxCubit extends Cubit<SellBitboxState> {
  final SellPaymentInfo _paymentInfo;
  final DfxFaucetService _faucetService;
  final DfxBlockchainApiService _blockchainService;
  final RealUnitSellPaymentInfoService _sellService;
  final AppStore _appStore;

  Timer? _ethPollingTimer;

  SellBitboxCubit({
    required SellPaymentInfo paymentInfo,
    required DfxFaucetService faucetService,
    required DfxBlockchainApiService blockchainService,
    required RealUnitSellPaymentInfoService sellService,
    required AppStore appStore,
  }) : _paymentInfo = paymentInfo,
       _faucetService = faucetService,
       _blockchainService = blockchainService,
       _sellService = sellService,
       _appStore = appStore,
       super(SellBitboxCheckingEth()) {
    scheduleMicrotask(_checkEthBalance);
  }

  Future<void> _checkEthBalance() async {
    try {
      emit(SellBitboxCheckingEth());
      final credentials = _appStore.wallet.currentAccount.primaryAddress;
      if (credentials is BitboxCredentials && !credentials.isConnected) {
        emit(SellBitboxBitboxRequired());
        return;
      }

      if (_paymentInfo.ethBalance >= _paymentInfo.requiredGasEth) {
        emit(SellBitboxEthReady());
      } else {
        await _requestFaucet();
      }
    } catch (e) {
      emit(SellBitboxError(e.toString()));
    }
  }

  Future<void> retryAfterConnection() => _checkEthBalance();

  Future<void> _requestFaucet() async {
    try {
      emit(SellBitboxRequestingFaucet());
      await _faucetService.requestFaucet();
      emit(SellBitboxWaitingForEth());
      _startEthPolling();
    } catch (e) {
      emit(SellBitboxError(e.toString()));
    }
  }

  void _startEthPolling() {
    _ethPollingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final balance = await _blockchainService.getEthBalance(_appStore.primaryAddress);
        if (balance >= _paymentInfo.requiredGasEth) {
          _ethPollingTimer?.cancel();
          emit(SellBitboxEthReady());
        }
      } catch (_) {
        // keep polling on transient errors
      }
    });
  }

  Future<void> proceedToSwap() async {
    try {
      emit(SellBitboxPreparingSwap());
      final transactions = await _sellService.createUnsignedTransactions(_paymentInfo.id);
      emit(SellBitboxAwaitingSwapConfirm(transactions.swap, transactions.deposit));
    } catch (e) {
      emit(SellBitboxError(e.toString()));
    }
  }

  Future<void> confirmSwap() async {
    final swapState = state;
    if (swapState is! SellBitboxAwaitingSwapConfirm) return;

    final credentials = _appStore.wallet.currentAccount.primaryAddress;
    if (credentials is! BitboxCredentials) {
      emit(SellBitboxError('BitBox wallet not connected'));
      return;
    }

    try {
      emit(SellBitboxSwapping());
      final signedSwap = await _signTransaction(swapState.rawSwapTransaction, credentials);
      emit(SellBitboxAwaitingDepositConfirm(signedSwap, swapState.rawDepositTransaction));
    } catch (e) {
      emit(SellBitboxError(e.toString()));
    }
  }

  Future<void> confirmDeposit() async {
    final depositState = state;
    if (depositState is! SellBitboxAwaitingDepositConfirm) return;

    final credentials = _appStore.wallet.currentAccount.primaryAddress;
    if (credentials is! BitboxCredentials) {
      emit(SellBitboxError('BitBox wallet not connected'));
      return;
    }

    try {
      emit(SellBitboxDepositing());
      final signedDeposit = await _signTransaction(depositState.rawDepositTransaction, credentials);
      await _sellService.broadcastTransaction(
        _paymentInfo.id,
        depositState.signedSwapTransaction,
      );
      await _broadcastDepositAndConfirm(depositState.signedSwapTransaction, signedDeposit);
    } catch (e) {
      emit(SellBitboxError(e.toString()));
    }
  }

  Future<void> retryDeposit() async {
    final retryState = state;
    if (retryState is! SellBitboxDepositRetry) return;

    try {
      emit(SellBitboxDepositing());
      await _broadcastDepositAndConfirm(
        retryState.signedSwapTransaction,
        retryState.signedDepositTransaction,
      );
    } catch (e) {
      emit(
        SellBitboxDepositRetry(
          retryState.signedSwapTransaction,
          retryState.signedDepositTransaction,
          e.toString(),
        ),
      );
    }
  }

  Future<void> _broadcastDepositAndConfirm(String signedSwap, String signedDeposit) async {
    try {
      final txHash = await _sellService.broadcastTransaction(
        _paymentInfo.id,
        signedDeposit,
      );
      await _sellService.confirmPaymentWithTxHash(_paymentInfo, txHash);
      emit(SellBitboxSuccess());
    } catch (e) {
      emit(SellBitboxDepositRetry(signedSwap, signedDeposit, e.toString()));
    }
  }

  Future<String> _signTransaction(String rawTransaction, BitboxCredentials credentials) async {
    final payload = Uint8List.fromList(
      convert.hex.decode(
        rawTransaction.startsWith('0x') ? rawTransaction.substring(2) : rawTransaction,
      ),
    );
    final sig = await credentials.signToSignature(
      payload,
      chainId: _appStore.apiConfig.asset.chainId,
      isEIP1559: true,
    );
    final r = sig.r.toRadixString(16).padLeft(64, '0');
    final s = sig.s.toRadixString(16).padLeft(64, '0');
    return jsonEncode({'unsignedTx': rawTransaction, 'r': '0x$r', 's': '0x$s', 'v': sig.v});
  }

  @override
  Future<void> close() {
    _ethPollingTimer?.cancel();
    return super.close();
  }
}
