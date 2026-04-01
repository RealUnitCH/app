import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/balance_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_widget_service.dart';
import 'package:realunit_wallet/packages/service/settings_service.dart';
import 'package:realunit_wallet/packages/service/transaction_history_service.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(
    this._walletService,
    this._balanceService,
    this._transactionHistoryService,
    this._dfxService,
    this._settingsService,
    this._appStore,
  ) : super(const HomeState()) {
    on<LoadCurrentWalletEvent>(_onLoadCurrentWallet);
    on<LoadWalletEvent>(_onLoadWallet);
    on<DeleteCurrentWalletEvent>(_onDeleteCurrentWallet);
    on<CompleteOnboardingEvent>(_onCompleteOnboarding);
    on<AcceptSoftwareTermsEvent>(_onAcceptSoftwareTerms);
    on<DebugAuthCompleteEvent>(_onDebugAuthComplete);

    add(const LoadCurrentWalletEvent());
  }

  final WalletService _walletService;
  final BalanceService _balanceService;
  final TransactionHistoryService _transactionHistoryService;
  final DfxWidgetService _dfxService;
  final SettingsService _settingsService;
  final AppStore _appStore;

  Future<void> _onLoadCurrentWallet(LoadCurrentWalletEvent event, Emitter<HomeState> emit) async {
    emit(
      state.copyWith(
        isLoadingWallet: true,
        softwareTermsAccepted: _settingsService.isSoftwareTermsAccepted,
      ),
    );

    if (state.openWallet != null || !_walletService.hasWallet()) {
      emit(state.copyWith(isLoadingWallet: false));
      return;
    }
    try {
      final wallet = await _walletService.getCurrentWallet();
      _appStore.wallet = wallet;

      emit(
        state.copyWith(
          openWallet: wallet,
          isLoadingWallet: false,
          onboardingCompleted: _settingsService.isTermsAccepted,
        ),
      );

      await setupFiatService(emit);
    } catch (e) {
      developer.log('Something went wrong during wallet loading', error: e);
      emit(state.copyWith(isLoadingWallet: false));

      return;
    }

    _balanceService.updateBalances(_appStore.primaryAddress);
    _balanceService.startSync(_appStore.primaryAddress);
    _transactionHistoryService.apiBasedSync();
    _transactionHistoryService.explorerAssistedScan();
    _transactionHistoryService.ponderBasedSync();
  }

  Future<void> _onDeleteCurrentWallet(
    DeleteCurrentWalletEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(isLoadingWallet: true));

    _dfxService.invalidateAuthToken();
    await _walletService.deleteCurrentWallet();
    _settingsService.setTermsAccepted(false);
    emit(
      HomeState(
        openWallet: null,
        isLoadingWallet: false,
        isFiatServiceAvailable: false,
        softwareTermsAccepted: state.softwareTermsAccepted,
      ),
    );
  }

  Future<void> _onLoadWallet(LoadWalletEvent event, Emitter<HomeState> emit) async {
    _appStore.wallet = event.wallet;
    _balanceService.updateBalances(_appStore.primaryAddress);
    _balanceService.startSync(_appStore.primaryAddress);
    _transactionHistoryService.apiBasedSync();
    _transactionHistoryService.explorerAssistedScan();
    _transactionHistoryService.ponderBasedSync();

    emit(state.copyWith(openWallet: _appStore.wallet, isLoadingWallet: false));

    await setupFiatService(emit);
  }

  Future<void> setupFiatService(Emitter<HomeState> emit) async {
    if (_appStore.wallet.walletType != WalletType.software) return;
    try {
      await _dfxService.getAuthToken();
      emit(state.copyWith(isFiatServiceAvailable: _dfxService.isAvailable));
    } catch (_) {}
  }

  void _onCompleteOnboarding(HomeEvent event, Emitter<HomeState> emit) {
    _settingsService.setTermsAccepted(true);
    emit(state.copyWith(onboardingCompleted: true));
  }

  void _onAcceptSoftwareTerms(AcceptSoftwareTermsEvent event, Emitter<HomeState> emit) {
    _settingsService.setSoftwareTermsAccepted(true);
    emit(state.copyWith(softwareTermsAccepted: true));
  }

  void _onDebugAuthComplete(DebugAuthCompleteEvent event, Emitter<HomeState> emit) {
    emit(state.copyWith(isDebugAuthenticated: true));
  }
}
