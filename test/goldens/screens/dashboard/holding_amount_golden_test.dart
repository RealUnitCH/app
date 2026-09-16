import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/models/balance.dart';
import 'package:realunit_wallet/models/portfolio_value_point.dart';
import 'package:realunit_wallet/models/price_point.dart';
import 'package:realunit_wallet/models/transaction.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/repository/transaction_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/models/transactions/dto/transactions_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_pdf_service.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_referral_service.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';
import 'package:realunit_wallet/screens/dashboard/bloc/balance_cubit.dart';
import 'package:realunit_wallet/screens/dashboard/bloc/dashboard_bloc.dart';
import 'package:realunit_wallet/screens/dashboard/bloc/pending_transactions_cubit.dart';
import 'package:realunit_wallet/screens/dashboard/dashboard_page.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/styles/currency.dart';
import 'package:realunit_wallet/styles/language.dart';

import '../../../helper/helper.dart';

/// Pixel baselines for every holding-amount surface of the incident
/// (77994 after Empfangen, 85194 after Kauf of 7200) plus Verkauf,
/// on-chain transfer in/out, hide-amounts, EUR/CHF, and EN labels.
///
/// MockCubit is allowed here: goldens pin the *rendered* amount, they do
/// not catch the emit-skip (that is the real-cubit catalog). Together they
/// cover the bug class: cubit emits the new total, and the screenshot
/// shows it.
class _MockDashboardBloc extends MockBloc<DashboardEvent, DashboardState>
    implements DashboardBloc {}

class _MockBalanceCubit extends MockCubit<Balance> implements BalanceCubit {}

class _MockPendingTransactionsCubit extends MockCubit<List<TransactionDto>>
    implements PendingTransactionsCubit {}

class _MockTransactionRepository extends Mock implements TransactionRepository {}

class _MockRealUnitPdfService extends Mock implements RealUnitPdfService {}

class _MockApiConfig extends Mock implements ApiConfig {}

void main() {
  const walletAddress = '0x064Bf75c3f07Af83c8Ed85dF6c825dC232f6023E';
  const brokerbot = '0xcff32c60d5d71f0b0b0b0b0b0b0b0b0b0b0bdd6d';
  const sender = '0xe9b30f4b0b309c1e4a1de7e7cde1d46e17a7e20c';
  const recipient = '0x1111111111111111111111111111111111111111';

  const empfangen = 77994;
  const kauf = 85194;
  const transferIn = 78094;
  const transferOut = 85094;

  // 1.46 EUR as in the incident Bestand row (2 implied decimals).
  final priceEur = BigInt.from(146);
  final priceChf = BigInt.from(153);

  late _MockDashboardBloc dashboardBloc;
  late _MockBalanceCubit balanceCubit;
  late _MockPendingTransactionsCubit pendingTxCubit;
  late MockSettingsBloc settingsBloc;
  final transactionRepository = _MockTransactionRepository();

  Balance holding(int shares) => Balance(
        chainId: realUnitAsset.chainId,
        contractAddress: realUnitAsset.address,
        walletAddress: walletAddress,
        balance: BigInt.from(shares),
        asset: realUnitAsset,
      );

  Transaction tx({
    required String id,
    required int shares,
    required DateTime at,
    required TransferCategory category,
    required String from,
    required String to,
  }) =>
      Transaction(
        height: 200,
        txId: id,
        chainId: 1,
        senderAddress: from,
        receiverAddress: to,
        amount: BigInt.from(shares),
        asset: realUnitAsset,
        type: TransactionTypes.tokenTransfer,
        category: category,
        note: null,
        data: null,
        timestamp: at,
      );

  final empfangenTx = tx(
    id: '0xc94e',
    shares: 77993,
    at: DateTime.utc(2026, 8, 14, 7, 29),
    category: TransferCategory.transferIn,
    from: sender,
    to: walletAddress,
  );
  final seedTx = tx(
    id: '0xa247',
    shares: 1,
    at: DateTime.utc(2026, 8, 14, 7, 23),
    category: TransferCategory.transferIn,
    from: sender,
    to: walletAddress,
  );
  final kaufTx = tx(
    id: '0x469e',
    shares: 7200,
    at: DateTime.utc(2026, 9, 8, 7, 31),
    category: TransferCategory.purchase,
    from: brokerbot,
    to: walletAddress,
  );
  final verkaufTx = tx(
    id: '0xsale',
    shares: 7200,
    at: DateTime.utc(2026, 9, 10, 9),
    category: TransferCategory.sale,
    from: walletAddress,
    to: brokerbot,
  );
  final extraInTx = tx(
    id: '0xin100',
    shares: 100,
    at: DateTime.utc(2026, 9, 12, 11),
    category: TransferCategory.transferIn,
    from: sender,
    to: walletAddress,
  );
  final extraOutTx = tx(
    id: '0xout100',
    shares: 100,
    at: DateTime.utc(2026, 9, 12, 12),
    category: TransferCategory.transferOut,
    from: walletAddress,
    to: recipient,
  );

  List<PricePoint> prices(BigInt p) => [
        PricePoint(asset: realUnitAsset, price: p, time: DateTime.utc(2026, 8, 14)),
        PricePoint(asset: realUnitAsset, price: p, time: DateTime.utc(2026, 9, 8)),
      ];

  List<PortfolioValuePoint> history(int shares, BigInt p) => [
        PortfolioValuePoint(
          value: BigInt.from(empfangen) * p,
          balance: BigInt.from(empfangen),
          time: DateTime.utc(2026, 8, 14),
        ),
        PortfolioValuePoint(
          value: BigInt.from(shares) * p,
          balance: BigInt.from(shares),
          time: DateTime.utc(2026, 9, 8),
        ),
      ];

  DashboardState dash({
    required int shares,
    required Currency currency,
    required BigInt price,
  }) =>
      DashboardState(
        price: price,
        priceChart: prices(price),
        portfolioHistory: history(shares, price),
        currency: currency,
      );

  setUpAll(() {
    final getIt = GetIt.instance;
    final apiConfig = _MockApiConfig();
    final appStore = MockAppStore();
    when(() => apiConfig.asset).thenReturn(realUnitAsset);
    when(() => appStore.apiConfig).thenReturn(apiConfig);
    when(() => appStore.primaryAddress).thenReturn(walletAddress);
    getIt.registerSingleton<AppStore>(appStore);
    getIt.registerSingleton<RealUnitPdfService>(_MockRealUnitPdfService());
    getIt.registerSingleton<TransactionRepository>(transactionRepository);
    getIt.registerSingleton<RealUnitReferralService>(
      MockRealUnitReferralService(),
    );
  });

  tearDownAll(() async => GetIt.instance.reset());

  setUp(() {
    dashboardBloc = _MockDashboardBloc();
    balanceCubit = _MockBalanceCubit();
    pendingTxCubit = _MockPendingTransactionsCubit();
    settingsBloc = MockSettingsBloc();

    when(() => pendingTxCubit.state).thenReturn(const <TransactionDto>[]);
    when(() => balanceCubit.asset).thenReturn(realUnitAsset);
    when(() => transactionRepository.watchTransactionsOfAssets(any(), any(), any()))
        .thenAnswer((_) => const Stream<List<Transaction>>.empty());
  });

  Widget subject() => MultiBlocProvider(
        providers: [
          BlocProvider<SettingsBloc>.value(value: settingsBloc),
          BlocProvider<DashboardBloc>.value(value: dashboardBloc),
          BlocProvider<BalanceCubit>.value(value: balanceCubit),
          BlocProvider<PendingTransactionsCubit>.value(value: pendingTxCubit),
        ],
        child: const DashboardView(),
      );

  void seed({
    required int shares,
    required List<Transaction> txs,
    Currency currency = Currency.eur,
    Language language = Language.de,
    bool hideAmounts = false,
    BigInt? price,
  }) {
    final p = price ?? (currency == Currency.eur ? priceEur : priceChf);
    when(() => settingsBloc.state).thenReturn(
      SettingsState(
        language: language,
        currency: currency,
        hideAmounts: hideAmounts,
      ),
    );
    when(() => balanceCubit.state).thenReturn(holding(shares));
    when(() => dashboardBloc.state).thenReturn(
      dash(shares: shares, currency: currency, price: p),
    );
    when(() => transactionRepository.watchTransactionsOfAssets(any(), any(), any()))
        .thenAnswer((_) => Stream.value(txs));
  }

  group('$DashboardView holding-amount variants', () {
    goldenTest(
      'Empfangen only — Bestand 77994, last txs Empfangen',
      fileName: 'holding_empfangen',
      constraints: phoneConstraints,
      builder: () {
        seed(shares: empfangen, txs: [empfangenTx, seedTx]);
        return wrapForGolden(subject());
      },
    );

    goldenTest(
      'after Kauf — Bestand 85194, last txs Kauf + Empfangen (incident fixed)',
      fileName: 'holding_kauf',
      constraints: phoneConstraints,
      builder: () {
        seed(shares: kauf, txs: [kaufTx, empfangenTx]);
        return wrapForGolden(subject());
      },
    );

    goldenTest(
      'after Verkauf — Bestand 77994, last txs Verkauf',
      fileName: 'holding_verkauf',
      constraints: phoneConstraints,
      builder: () {
        seed(shares: empfangen, txs: [verkaufTx, kaufTx, empfangenTx]);
        return wrapForGolden(subject());
      },
    );

    goldenTest(
      'after on-chain transferIn — Bestand 78094',
      fileName: 'holding_transfer_in',
      constraints: phoneConstraints,
      builder: () {
        seed(shares: transferIn, txs: [extraInTx, kaufTx, empfangenTx]);
        return wrapForGolden(subject());
      },
    );

    goldenTest(
      'after on-chain transferOut — Bestand 85094',
      fileName: 'holding_transfer_out',
      constraints: phoneConstraints,
      builder: () {
        seed(shares: transferOut, txs: [extraOutTx, kaufTx, empfangenTx]);
        return wrapForGolden(subject());
      },
    );

    goldenTest(
      'after Kauf with amounts hidden',
      fileName: 'holding_kauf_hidden',
      constraints: phoneConstraints,
      builder: () {
        seed(shares: kauf, txs: [kaufTx, empfangenTx], hideAmounts: true);
        return wrapForGolden(subject());
      },
    );

    goldenTest(
      'after Kauf in CHF',
      fileName: 'holding_kauf_chf',
      constraints: phoneConstraints,
      builder: () {
        seed(
          shares: kauf,
          txs: [kaufTx, empfangenTx],
          currency: Currency.chf,
        );
        return wrapForGolden(subject());
      },
    );

    goldenTest(
      'after Kauf in English (Buy / Received labels)',
      fileName: 'holding_kauf_en',
      constraints: phoneConstraints,
      builder: () {
        seed(
          shares: kauf,
          txs: [kaufTx, empfangenTx],
          language: Language.en,
        );
        return wrapForGolden(subject(), locale: const Locale('en'));
      },
    );
  });
}
