import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/models/asset.dart';
import 'package:realunit_wallet/models/balance.dart';
import 'package:realunit_wallet/models/blockchain.dart';
import 'package:realunit_wallet/packages/service/alias_resolver/alias_resolver.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/balance_service.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';
import 'package:realunit_wallet/packages/wallet/is_evm_address.dart';

part 'send_event.dart';
part 'send_state.dart';

class SendBloc extends Bloc<SendEvent, SendState> {
  SendBloc(
    this._appStore,
    this._balanceService, {
    required Asset asset,
    String receiver = '',
    String amount = '0',
  }) : super(SendState(asset: asset, receiver: receiver, amount: amount)) {
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

  final AppStore _appStore;
  final BalanceService _balanceService;

  Future<void> _onReceiverChanged(ReceiverChanged event, Emitter<SendState> emit) async {
    emit(state.copyWith(receiver: event.receiver));
    if (event.receiver.contains('.')) {
      final resolvedAlias = await AliasResolver.resolve(
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
        emit(
          state.copyAlias(
            alias: AliasRecord(
              address: value!.text!,
              name: S.current.fromClipboard,
            ),
          ),
        );
      }
    }
  }

  Future<void> _onSelectAlias(SelectAlias event, Emitter<SendState> emit) async {
    emit(state.copyWith(receiver: state.alias?.address));
  }

  void _onAmountAdd(AmountChangedAdd event, Emitter<SendState> emit) {
    emit(
      state.copyWith(
        amount: state.amount == '0' ? event.amount.toString() : '${state.amount}${event.amount}',
      ),
    );
  }

  void _onAmountDecimal(AmountChangedDecimal event, Emitter<SendState> emit) {
    emit(state.copyWith(amount: '${state.amount.replaceAll('.', '')}.'));
  }

  void _onAmountRemove(AmountChangedDelete event, Emitter<SendState> emit) {
    emit(
      state.copyWith(
        amount: state.amount.length > 1 ? state.amount.substring(0, state.amount.length - 1) : '0',
      ),
    );
  }

  void _onAssetChanged(AssetChanged event, Emitter<SendState> emit) {
    emit(state.copyWith(asset: event.asset));
  }

  Future<void> _onSubmitted(SendSubmitted event, Emitter<SendState> emit) async {
    // Transaction sending not yet available via API
    emit(state.copyWith(status: SendStatus.failure));
  }

  Future<void> _onLoadBalances(LoadBalances event, Emitter<SendState> emit) async {
    final balances = <Balance>[];
    final owner = _appStore.wallet.currentAccount.primaryAddress.address.hexEip55;
    for (final asset in [
      dEUROAsset,
      dEUROPolygonAsset,
      dEUROArbitrumAsset,
      dEUROBaseAsset,
      dEUROOptimismAsset,
    ]) {
      final balance = await _balanceService.getBalance(asset, owner);
      if (balance != null && balance.balance > BigInt.zero) {
        balances.add(balance);
      }
    }

    emit(state.copyWith(balances: balances));
  }
}
