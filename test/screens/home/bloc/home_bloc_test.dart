import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/balance_service.dart';
import 'package:realunit_wallet/packages/service/session_cache.dart';
import 'package:realunit_wallet/packages/service/settings_service.dart';
import 'package:realunit_wallet/packages/service/transaction_history_service.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/setup/routing/boot_navigation.dart';

class _MockWalletService extends Mock implements WalletService {}

class _MockBalanceService extends Mock implements BalanceService {}

class _MockTransactionHistoryService extends Mock implements TransactionHistoryService {}

class _MockSettingsService extends Mock implements SettingsService {}

class _MockAppStore extends Mock implements AppStore {}

class _MockBitboxService extends Mock implements BitboxService {}

class _MockSessionCache extends Mock implements SessionCache {}

class _FakeWallet extends Fake implements AWallet {}

const _debugAddress = '0x0000000000000000000000000000000000000001';
const _primary = '0x00000000000000000000000000000000deadbeef';

void main() {
  late _MockWalletService walletService;
  late _MockBalanceService balanceService;
  late _MockTransactionHistoryService transactionHistoryService;
  late _MockSettingsService settingsService;
  late _MockAppStore appStore;
  late _MockBitboxService bitboxService;
  late _MockSessionCache sessionCache;

  setUpAll(() {
    registerFallbackValue(_FakeWallet());
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    walletService = _MockWalletService();
    balanceService = _MockBalanceService();
    transactionHistoryService = _MockTransactionHistoryService();
    settingsService = _MockSettingsService();
    appStore = _MockAppStore();
    bitboxService = _MockBitboxService();
    sessionCache = _MockSessionCache();

    when(() => walletService.hasWallet()).thenReturn(true);
    when(() => walletService.currentWalletNeedsAddressRecovery()).thenAnswer((_) async => false);
    when(() => settingsService.isSoftwareTermsAccepted).thenReturn(true);
    when(() => settingsService.isTermsAccepted).thenReturn(true);
    when(() => settingsService.setTermsAccepted(any())).thenReturn(null);
    when(() => appStore.primaryAddress).thenReturn(_primary);
    when(() => appStore.sessionCache).thenReturn(sessionCache);
    when(() => sessionCache.clear()).thenAnswer((_) async {});
    when(() => balanceService.updateBalance(any())).thenAnswer((_) async {});
    when(() => balanceService.startSync(any())).thenReturn(null);
    when(() => transactionHistoryService.apiBasedSync()).thenAnswer((_) async {});
    when(() => bitboxService.stopConnectionStatusObserver()).thenReturn(null);
  });

  HomeBloc build() => HomeBloc(
    walletService,
    balanceService,
    transactionHistoryService,
    settingsService,
    appStore,
    bitboxService,
  );

  group('SwitchWalletEvent', () {
    test('always reloads even when openWallet is already set', () async {
      final first = DebugWallet(1, 'Software', _debugAddress);
      final second = DebugWallet(2, 'BitBox', _debugAddress);
      when(() => walletService.getCurrentWallet()).thenAnswer((_) async => first);
      when(() => walletService.switchCurrentWallet(2)).thenAnswer((_) async => second);

      final bloc = build();
      await bloc.stream.firstWhere((s) => s.hasWallet);
      bloc.add(const LoadCurrentWalletEvent());
      await bloc.stream.firstWhere((s) => s.openWallet == first);

      bloc.add(const SwitchWalletEvent(2));
      await bloc.stream.firstWhere((s) => s.openWallet == second);

      expect(bloc.state.openWallet, same(second));
      verify(() => walletService.switchCurrentWallet(2)).called(1);
      verify(() => appStore.wallet = second).called(1);
      await bloc.close();
    });
  });

  group('DeleteCurrentWalletEvent when another wallet remains', () {
    test('loads the remaining wallet and does not clear terms or the deeplink', () async {
      addTearDown(clearPendingPaymentDeeplink);
      stashPendingPaymentDeeplink('lightning:LNURL1DP68GURN8GHJ7VF3XGENJVE5UMD');
      final remaining = DebugWallet(2, 'BitBox', _debugAddress);
      when(() => walletService.deleteCurrentWallet()).thenAnswer((_) async => 2);
      when(() => walletService.getWalletById(2)).thenAnswer((_) async => remaining);

      final bloc = build();
      await bloc.stream.firstWhere((s) => s.hasWallet);

      bloc.add(const DeleteCurrentWalletEvent());
      await bloc.stream.firstWhere(
        (s) => s.openWallet == remaining && s.hasWallet && !s.isLoadingWallet,
      );

      expect(bloc.state.hasWallet, isTrue);
      expect(bloc.state.openWallet, same(remaining));
      verifyNever(() => settingsService.setTermsAccepted(false));
      expect(peekPendingPaymentDeeplink(), isNotNull);
      await bloc.close();
    });
  });
}
