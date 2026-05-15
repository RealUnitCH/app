import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/balance_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_widget_service.dart';
import 'package:realunit_wallet/packages/service/settings_service.dart';
import 'package:realunit_wallet/packages/service/transaction_history_service.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';

class _MockWalletService extends Mock implements WalletService {}

class _MockBalanceService extends Mock implements BalanceService {}

class _MockTransactionHistoryService extends Mock implements TransactionHistoryService {}

class _MockDfxWidgetService extends Mock implements DfxWidgetService {}

class _MockSettingsService extends Mock implements SettingsService {}

class _MockAppStore extends Mock implements AppStore {}

class _MockBitboxService extends Mock implements BitboxService {}

void main() {
  late _MockWalletService walletService;
  late _MockBalanceService balanceService;
  late _MockTransactionHistoryService transactionHistoryService;
  late _MockDfxWidgetService dfxService;
  late _MockSettingsService settingsService;
  late _MockAppStore appStore;
  late _MockBitboxService bitboxService;

  setUp(() {
    walletService = _MockWalletService();
    balanceService = _MockBalanceService();
    transactionHistoryService = _MockTransactionHistoryService();
    dfxService = _MockDfxWidgetService();
    settingsService = _MockSettingsService();
    appStore = _MockAppStore();
    bitboxService = _MockBitboxService();

    // Sensible defaults so the auto-fired CheckWalletExistsEvent doesn't crash.
    when(() => walletService.hasWallet()).thenReturn(false);
    when(() => settingsService.isSoftwareTermsAccepted).thenReturn(false);
    when(() => settingsService.isTermsAccepted).thenReturn(false);
  });

  HomeBloc build() => HomeBloc(
        walletService,
        balanceService,
        transactionHistoryService,
        dfxService,
        settingsService,
        appStore,
        bitboxService,
      );

  group('$HomeBloc', () {
    group('initial CheckWalletExistsEvent', () {
      test('no wallet present → hasWallet=false, onboardingCompleted=false', () async {
        when(() => walletService.hasWallet()).thenReturn(false);
        when(() => settingsService.isSoftwareTermsAccepted).thenReturn(true);
        when(() => settingsService.isTermsAccepted).thenReturn(true);

        final bloc = build();
        await bloc.stream.firstWhere(
          (s) => s.softwareTermsAccepted == true && s.hasWallet == false,
        );

        expect(bloc.state.hasWallet, isFalse);
        // Without a wallet, onboardingCompleted is forced false regardless of
        // the persisted termsAccepted flag.
        expect(bloc.state.onboardingCompleted, isFalse);
        expect(bloc.state.softwareTermsAccepted, isTrue);
      });

      test('wallet present + terms accepted → onboardingCompleted=true', () async {
        when(() => walletService.hasWallet()).thenReturn(true);
        when(() => settingsService.isSoftwareTermsAccepted).thenReturn(true);
        when(() => settingsService.isTermsAccepted).thenReturn(true);

        final bloc = build();
        await bloc.stream.firstWhere((s) => s.hasWallet);

        expect(bloc.state.hasWallet, isTrue);
        expect(bloc.state.onboardingCompleted, isTrue);
        expect(bloc.state.softwareTermsAccepted, isTrue);
      });

      test('wallet present + terms NOT yet accepted → onboardingCompleted=false', () async {
        when(() => walletService.hasWallet()).thenReturn(true);
        when(() => settingsService.isSoftwareTermsAccepted).thenReturn(true);
        when(() => settingsService.isTermsAccepted).thenReturn(false);

        final bloc = build();
        await bloc.stream.firstWhere((s) => s.hasWallet);

        expect(bloc.state.hasWallet, isTrue);
        expect(bloc.state.onboardingCompleted, isFalse);
      });
    });

    group('CompleteOnboardingEvent', () {
      test('writes termsAccepted=true and emits onboardingCompleted=true', () async {
        final bloc = build();
        await bloc.stream.firstWhere((s) => s.hasWallet == false);

        bloc.add(const CompleteOnboardingEvent());
        await bloc.stream.firstWhere((s) => s.onboardingCompleted);

        expect(bloc.state.onboardingCompleted, isTrue);
        verify(() => settingsService.setTermsAccepted(true)).called(1);
      });
    });

    group('AcceptSoftwareTermsEvent', () {
      test('writes softwareTermsAccepted=true and emits the new state', () async {
        final bloc = build();
        await bloc.stream.firstWhere((s) => s.hasWallet == false);

        bloc.add(const AcceptSoftwareTermsEvent());
        await bloc.stream.firstWhere((s) => s.softwareTermsAccepted);

        expect(bloc.state.softwareTermsAccepted, isTrue);
        verify(() => settingsService.setSoftwareTermsAccepted(true)).called(1);
      });
    });
  });
}
