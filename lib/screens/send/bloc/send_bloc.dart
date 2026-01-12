import 'dart:async';
import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/models/asset.dart';
import 'package:realunit_wallet/models/balance.dart';
import 'package:realunit_wallet/models/blockchain.dart';
import 'package:realunit_wallet/packages/service/alias_resolver/alias_resolver.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/balance_service.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';
import 'package:realunit_wallet/packages/utils/parse_fixed.dart';
import 'package:realunit_wallet/packages/wallet/create_transaction.dart';
import 'package:realunit_wallet/packages/wallet/is_evm_address.dart';
import 'package:realunit_wallet/packages/wallet/transaction_priority.dart';
import 'package:realunit_wallet/router.dart';
import 'package:realunit_wallet/screens/send/bloc/gas_fee_cubit.dart';
import 'package:realunit_wallet/screens/transaction_sent/transaction_sent_page.dart';
import 'package:realunit_wallet/widgets/error_bottom_sheet.dart';

part 'send_event.dart';
part 'send_state.dart';

class SendBloc extends Bloc<SendEvent, SendState> {
  SendBloc(this._appStore, this._balanceService,
      {required Asset asset, String receiver = '', String amount = '0'})
      : gasFeeCubit = GasFeeCubit(_appStore, Blockchain.getFromChainId(asset.chainId)),
        super(SendState(asset: asset, receiver: receiver, amount: amount)) {
    on<SelectAlias>(_onSelectAlias);
    on<ReceiverChanged>(_onReceiverChanged);
    on<PasteReceiver>(_onPasteReceiver);
    on<AmountChangedAdd>(_onAmountAdd);
    on<AmountChangedDecimal>(_onAmountDecimal);
    on<AmountChangedDelete>(_onAmountRemove);
    on<AssetChanged>(_onAssetChanged);
    on<SendSubmitted>(_onSubmitted);
    on<LoadBalances>(_onLoadBalances);

    add(const LoadBalances());
    add(const PasteReceiver());
  }

  @override
  Future<void> close() async {
    await gasFeeCubit.close();
    return super.close();
  }

  final GasFeeCubit gasFeeCubit;
  final AppStore _appStore;
  final BalanceService _balanceService;

  Future<void> _onReceiverChanged(ReceiverChanged event, Emitter<SendState> emit) async {
    emit(state.copyWith(receiver: event.receiver));
    if (event.receiver.contains('.')) {
      final resolvedAlias = await AliasResolver.resolve(
        _appStore.getClient(1),
        alias: event.receiver,
        ticker: state.asset.symbol,
        tickerFallback: 'ETH',
      );
      emit(state.copyAlias(alias: resolvedAlias));
    } else {
      emit(state.copyAlias());
    }
  }

  Future<void> _onPasteReceiver(PasteReceiver event, Emitter<SendState> emit) async {
    if (await Clipboard.hasStrings()) {
      final value = await Clipboard.getData('text/plain');
      if (value?.text?.isEthereumAddress == true) {
        emit(state.copyAlias(
          alias: AliasRecord(
            address: value!.text!,
            name: S.current.from_clipboard,
            description: '',
          ),
        ));
      }
    }
  }

  Future<void> _onSelectAlias(SelectAlias event, Emitter<SendState> emit) async {
    emit(state.copyWith(receiver: state.alias?.address));
  }

  void _onAmountAdd(AmountChangedAdd event, Emitter<SendState> emit) {
    emit(state.copyWith(
      amount: state.amount == '0' ? event.amount.toString() : '${state.amount}${event.amount}',
    ));
  }

  void _onAmountDecimal(AmountChangedDecimal event, Emitter<SendState> emit) {
    emit(state.copyWith(amount: '${state.amount.replaceAll('.', '')}.'));
  }

  void _onAmountRemove(AmountChangedDelete event, Emitter<SendState> emit) {
    emit(state.copyWith(
      amount: state.amount.length > 1 ? state.amount.substring(0, state.amount.length - 1) : '0',
    ));
  }

  void _onAssetChanged(AssetChanged event, Emitter<SendState> emit) {
    emit(state.copyWith(asset: event.asset));
    gasFeeCubit.blockchain = Blockchain.getFromChainId(state.asset.chainId);
  }

  Future<void> _onSubmitted(SendSubmitted event, Emitter<SendState> emit) async {
    if (state.receiver.isEthereumAddress) {
      final client = _appStore.getClient(state.blockchain.chainId);
      final ethBalance =
          await client.getBalance(_appStore.wallet.currentAccount.primaryAddress.address);
      if (ethBalance.getInWei < gasFeeCubit.state.gasFee) {
        return showModalBottomSheet(
          context: navigatorKey.currentContext!,
          builder: (_) => ErrorBottomSheet(
            message: S.current
                .error_not_enough_money(state.blockchain.nativeSymbol, state.blockchain.name),
          ),
        );
      }

      emit(state.copyWith(status: SendStatus.inProgress));
      try {
        final transaction = await createERC20Transaction(
          client,
          currentAccount: _appStore.wallet.currentAccount.primaryAddress,
          receiveAddress: state.receiver,
          amount: parseFixed(state.amount, state.asset.decimals),
          contractAddress: state.asset.address,
          chainId: state.blockchain.chainId,
          priority: TransactionPriority.slow,
        );

        final id = await transaction();
        developer.log(id, name: 'SendBloc');
        emit(state.copyWith(status: SendStatus.success));

        if (navigatorKey.currentContext != null) {
          navigatorKey.currentContext?.pop();
          showCupertinoSheet(
            context: navigatorKey.currentContext!,
            builder: (_) => TransactionSentPage(
              title: S.current.transaction_sent,
              transactionId: id,
              blockchain: state.blockchain,
            ),
          );
        }
      } catch (e) {
        developer.log('Error during send!', error: e, name: 'SendBloc');
        emit(state.copyWith(status: SendStatus.failure));
      }
    }
  }

  Future<void> _onLoadBalances(LoadBalances event, Emitter<SendState> emit) async {
    final balances = <Balance>[];
    final owner = _appStore.wallet.currentAccount.primaryAddress.address.hexEip55;
    for (final asset in [
      dEUROAsset,
      dEUROPolygonAsset,
      dEUROArbitrumAsset,
      dEUROBaseAsset,
      dEUROOptimismAsset
    ]) {
      final balance = await _balanceService.getBalance(asset, owner);
      if (balance != null && balance.balance > BigInt.zero) {
        balances.add(balance);
      }
    }

    emit(state.copyWith(balances: balances));
  }
}
