/// Catalog of production surfaces that `extends Cubit<Balance>`. Adding a
/// new balance cubit without a catalog entry and a real-cubit two-amount
/// regression test is a review-blocking gap.
///
/// Unlike a mock/`whenListen` of a single state, the self-test in
/// `holding_amount_catalog_test.dart` also **discovers** every
/// `extends Cubit<Balance>` under `lib/` and fails if any cubit is missing
/// here. Amount-ignoring `Balance.==` is the bug class this gates.
library;

/// One `Cubit<Balance>` surface under the holding-amount update contract.
class HoldingAmountSurface {
  const HoldingAmountSurface({
    required this.id,
    required this.description,
    required this.productionPath,
    required this.regressionTestPath,
  });

  final String id;
  final String description;

  /// Path under `lib/` of the production file that `extends Cubit<Balance>`.
  final String productionPath;

  /// Path under `test/` of the real-cubit two-amount regression test.
  final String regressionTestPath;
}

/// Living catalog — extend when adding a new `Cubit<Balance>`.
const kHoldingAmountCatalog = <HoldingAmountSurface>[
  HoldingAmountSurface(
    id: 'dashboard_balance',
    description: 'Dashboard Bestand row (Kauf / Empfangen)',
    productionPath: 'lib/screens/dashboard/bloc/balance_cubit.dart',
    regressionTestPath: 'test/screens/dashboard/balance_cubit_test.dart',
  ),
  HoldingAmountSurface(
    id: 'sell_and_send_balance',
    description: 'Sell + send available REALU (Verkauf / Gesendet)',
    productionPath: 'lib/screens/sell/cubits/sell_balance/sell_balance_cubit.dart',
    regressionTestPath: 'test/screens/sell/cubits/sell_balance_cubit_test.dart',
  ),
];
