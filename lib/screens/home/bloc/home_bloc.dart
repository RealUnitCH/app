import 'dart:developer' as developer;

import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/balance_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_service.dart';
import 'package:realunit_wallet/packages/service/transaction_history_service.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(this._walletService, this._balanceService,
      this._transactionHistoryService, this._dfxService, this._appStore)
      : super(HomeState()) {
    on<LoadCurrentWalletEvent>(_onLoadCurrentWallet);
    on<LoadWalletEvent>(_onLoadWallet);
    on<DeleteCurrentWalletEvent>(_onDeleteCurrentWallet);
  }

  final WalletService _walletService;
  final BalanceService _balanceService;
  final TransactionHistoryService _transactionHistoryService;
  final DFXService _dfxService;
  final AppStore _appStore;

  Future<void> _onLoadCurrentWallet(
      LoadCurrentWalletEvent event, Emitter<HomeState> emit) async {
    emit(state.copyWith(isLoadingWallet: true));

    if (state.openWallet != null || !_walletService.hasWallet()) {
      emit(state.copyWith(isLoadingWallet: false));
      return;
    }
    try {
      final wallet = await _walletService.getCurrentWallet();
      _appStore.wallet = wallet;

      emit(state.copyWith(openWallet: wallet, isLoadingWallet: false));

      await setupFiatService(emit);
    } catch (e) {
      developer.log('Something went wrong during wallet loading', error: e);
      emit(state.copyWith(isLoadingWallet: false));

      return;
    }

    _balanceService.updateERC20Balances(_appStore.primaryAddress);
    _balanceService.startSync(_appStore.primaryAddress);
    _transactionHistoryService.explorerAssistedScan();
    _transactionHistoryService.ponderBasedSync();
  }

  Future<void> _onDeleteCurrentWallet(
      DeleteCurrentWalletEvent event, Emitter<HomeState> emit) async {
    emit(state.copyWith(isLoadingWallet: true));

    _appStore.dfxAuthToken = null;
    await _walletService.deleteCurrentWallet();
    emit(HomeState(openWallet: null, isLoadingWallet: false, isFiatServiceAvailable: false));
  }

  Future<void> _onLoadWallet(
      LoadWalletEvent event, Emitter<HomeState> emit) async {
    _appStore.wallet = event.wallet;
    _balanceService.updateERC20Balances(_appStore.primaryAddress);
    _balanceService.startSync(_appStore.primaryAddress);
    _transactionHistoryService.explorerAssistedScan();
    _transactionHistoryService.ponderBasedSync();

    emit(state.copyWith(openWallet: _appStore.wallet, isLoadingWallet: false));

    await setupFiatService(emit);
  }

  Future<void> setupFiatService(Emitter<HomeState> emit) async {
    try {
      await _dfxService.getAuthToken();
      emit(state.copyWith(isFiatServiceAvailable: _dfxService.isAvailable));
    } catch (_) {}
  }
}
