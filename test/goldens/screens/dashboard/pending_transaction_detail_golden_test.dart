import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/service/dfx/models/transactions/dto/transactions_dto.dart';
import 'package:realunit_wallet/screens/dashboard/widgets/pending_transaction_detail_page.dart';

import '../../../helper/helper.dart';

void main() {
  // This test does not commit a PNG; the regenerate workflow writes it.

  final buy = TransactionDto(
    type: TransactionType.buy,
    inputAmount: 5000,
    inputAsset: 'CHF',
    outputAmount: 50,
    outputAsset: 'REALU',
    state: TransactionState.processing,
    date: DateTime.utc(2026, 5, 15, 10),
    sourceAccount: 'CH9300762011623852957',
    targetAccount: '0x1111111111111111111111111111111111111111',
  );

  goldenTest(
    'pending transaction detail',
    fileName: 'pending_transaction_detail',
    constraints: phoneConstraints,
    pumpBeforeTest: (tester) async {
      await tester.pump();
      expect(find.text('Kauf'), findsOneWidget);
      expect(find.text('5000.00 CHF'), findsOneWidget);
      expect(find.text('In Bearbeitung'), findsOneWidget);
      expect(find.text('CH9300762011623852957'), findsNothing);
      expect(find.text('IBAN'), findsNothing);
      expect(
        find.text('0x1111111111111111111111111111111111111111'),
        findsNothing,
      );
    },
    builder: () => wrapForGolden(
      PendingTransactionDetailPage(
        args: PendingTransactionDetailArgs(transaction: buy),
      ),
    ),
  );
}
