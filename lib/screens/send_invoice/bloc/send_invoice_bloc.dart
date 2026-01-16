import 'dart:async';
import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/models/asset.dart';
import 'package:realunit_wallet/models/blockchain.dart';
import 'package:realunit_wallet/packages/open_crypto_pay/models.dart';
import 'package:realunit_wallet/packages/open_crypto_pay/open_crypto_pay_service.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/balance_service.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';
import 'package:realunit_wallet/packages/utils/parse_fixed.dart';
import 'package:realunit_wallet/packages/wallet/create_transaction.dart';
import 'package:realunit_wallet/router.dart';
import 'package:realunit_wallet/screens/send/bloc/gas_fee_cubit.dart';
import 'package:realunit_wallet/screens/send_invoice/bloc/expiry_cubit.dart';
import 'package:realunit_wallet/screens/transaction_sent/transaction_sent_page.dart';
import 'package:realunit_wallet/widgets/error_bottom_sheet.dart';

part 'send_invoice_event.dart';
part 'send_invoice_state.dart';

class SendInvoiceBloc extends Bloc<SendInvoiceEvent, SendInvoiceState> {
  SendInvoiceBloc(this._appStore, this._openCryptoPayService, this._balanceService,
      {required OpenCryptoPayRequest invoice})
      : expiryCubit = ExpiryCubit(invoice.expiration),
        gasFeeCubit = GasFeeCubit(_appStore),
        super(SendInvoiceState(invoice: invoice)) {
    on<ChainChanged>(_onChainChanged);
    on<CancelInvoice>(_onCancelInvoice);
    on<SendSubmitted>(_onSubmitted);

    _selectPreferredBlockchain();
    // _startFeeSync();
  }

  @override
  Future<void> close() async {
    await gasFeeCubit.close();
    await expiryCubit.close();
    return super.close();
  }

  final ExpiryCubit expiryCubit;
  final GasFeeCubit gasFeeCubit;

  final AppStore _appStore;
  final OpenCryptoPayService _openCryptoPayService;
  final BalanceService _balanceService;

  void _onChainChanged(ChainChanged event, Emitter<SendInvoiceState> emit) {
    emit(state.copyWith(asset: _getAsset(event.blockchain)));
    gasFeeCubit.blockchain = event.blockchain;
  }

  Future<void> _onCancelInvoice(CancelInvoice event, Emitter<SendInvoiceState> emit) =>
      _openCryptoPayService.cancelOpenCryptoPayRequest(state.invoice);

  Future<void> _onSubmitted(SendSubmitted event, Emitter<SendInvoiceState> emit) async {
    final client = _appStore.getClient(state.asset.chainId);

    final ethBalance =
        await client.getBalance(_appStore.wallet.currentAccount.primaryAddress.address);
    if (ethBalance.getInWei < gasFeeCubit.state.gasFee) {
      return showModalBottomSheet(
        context: navigatorKey.currentContext!,
        builder: (_) => ErrorBottomSheet(
          message:
              S.current.errorNotEnoughMoney(state.blockchain.nativeSymbol, state.blockchain.name),
        ),
      );
    }

    emit(state.copyWith(status: SendStatus.inProgress));
    try {
      final gasPrice = state.invoice.methods[state.blockchain.name]!.first.gasFee;

      final uri = await _openCryptoPayService.getOpenCryptoPayAddress(state.invoice, state.asset);

      final transaction = await prepareERC20Transaction(
        client,
        currentAccount: _appStore.wallet.currentAccount.primaryAddress,
        receiveAddress: uri.address,
        amount: parseFixed(uri.amount, 18),
        contractAddress: state.asset.address,
        chainId: state.asset.chainId,
        gasPrice: gasPrice,
      );

      final id = await _openCryptoPayService.commitOpenCryptoPayRequest('0x$transaction',
          request: state.invoice, asset: state.asset);
      developer.log(id, name: 'SendInvoiceBloc');
      emit(state.copyWith(status: SendStatus.success));

      if (navigatorKey.currentContext != null) {
        navigatorKey.currentContext?.pop();
        showCupertinoSheet(
          context: navigatorKey.currentContext!,
          builder: (_) => TransactionSentPage(
            title: S.current.transactionSent,
            transactionId: id,
            blockchain: state.blockchain,
          ),
        );
      }
    } catch (e) {
      developer.log('Error during send!', error: e, name: 'SendInvoiceBloc');
      emit(state.copyWith(status: SendStatus.failure));
    }
  }

  Future<void> _selectPreferredBlockchain() async {
    for (final blockchain in [
      Blockchain.base,
      Blockchain.arbitrum,
      Blockchain.optimism,
      Blockchain.polygon,
      Blockchain.ethereum
    ]) {
      final asset = _getAsset(blockchain);
      final balance = await _balanceService.getBalance(asset, _appStore.primaryAddress);
      if (balance == null) continue;
      if (balance.balance > state.dEuroAmount) {
        add(ChainChanged(blockchain));
        break;
      }
    }
  }

  Asset _getAsset(Blockchain blockchain) {
    switch (blockchain) {
      case Blockchain.ethereum:
        return dEUROAsset;
      case Blockchain.sepolia:
        return realUnitTestAsset;
      case Blockchain.polygon:
        return dEUROPolygonAsset;
      case Blockchain.arbitrum:
        return dEUROArbitrumAsset;
      case Blockchain.base:
        return dEUROBaseAsset;
      case Blockchain.optimism:
        return dEUROOptimismAsset;
    }
  }
}
