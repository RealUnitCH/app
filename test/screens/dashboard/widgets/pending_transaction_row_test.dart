import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/service/dfx/models/transactions/dto/transactions_dto.dart';
import 'package:realunit_wallet/screens/dashboard/widgets/pending_transaction_row.dart';

import '../../../helper/helper.dart';

TransactionDto _tx({
  TransactionType? type,
  TransactionState? state,
  double? inputAmount,
  String? inputAsset,
}) =>
    TransactionDto(
      id: 1,
      type: type,
      state: state,
      inputAmount: inputAmount,
      inputAsset: inputAsset,
      date: DateTime.utc(2026, 5, 15, 10),
    );

void main() {
  group('$PendingTransactionRow', () {
    testWidgets('always renders a CupertinoActivityIndicator (still pending)',
        (tester) async {
      await tester.pumpApp(Scaffold(
        body: PendingTransactionRow(
          transaction: _tx(type: TransactionType.buy, state: TransactionState.processing),
        ),
      ));

      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    });

    testWidgets('buy vs sell produce DIFFERENT first-line labels', (tester) async {
      await tester.pumpApp(Scaffold(
        body: PendingTransactionRow(
          transaction: _tx(type: TransactionType.buy, state: TransactionState.processing),
        ),
      ));
      // Capture buy line.
      final buyLine = tester.widgetList<Text>(find.byType(Text)).first.data;

      await tester.pumpApp(Scaffold(
        body: PendingTransactionRow(
          transaction: _tx(type: TransactionType.sell, state: TransactionState.processing),
        ),
      ));
      final sellLine = tester.widgetList<Text>(find.byType(Text)).first.data;

      expect(buyLine, isNotNull);
      expect(sellLine, isNotNull);
      expect(buyLine, isNot(sellLine));
    });

    testWidgets('state=waitingForPayment vs other state produces DIFFERENT second-line labels',
        (tester) async {
      await tester.pumpApp(Scaffold(
        body: PendingTransactionRow(
          transaction: _tx(
            type: TransactionType.buy,
            state: TransactionState.waitingForPayment,
          ),
        ),
      ));
      final waitingSecondLine = tester.widgetList<Text>(find.byType(Text)).elementAt(1).data;

      await tester.pumpApp(Scaffold(
        body: PendingTransactionRow(
          transaction: _tx(
            type: TransactionType.buy,
            state: TransactionState.processing,
          ),
        ),
      ));
      final processingSecondLine =
          tester.widgetList<Text>(find.byType(Text)).elementAt(1).data;

      expect(waitingSecondLine, isNotNull);
      expect(processingSecondLine, isNotNull);
      expect(waitingSecondLine, isNot(processingSecondLine));
    });
  });
}
