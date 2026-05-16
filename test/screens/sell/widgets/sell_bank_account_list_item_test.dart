import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/service/dfx/models/bank_account/bank_account.dart';
import 'package:realunit_wallet/screens/sell/widgets/sell_bank_account_list_item.dart';
import 'package:realunit_wallet/styles/colors.dart';

import '../../../helper/helper.dart';

Widget _host(Widget child) => Scaffold(body: child);

void main() {
  group('$SellBankAccountListItem', () {
    testWidgets('isActive=true with name: bg is brand200, name visible',
        (tester) async {
      await tester.pumpApp(_host(
        SellBankAccountListItem(
          account: const BankAccount(
            id: 1,
            iban: 'CH9300762011623852957',
            name: 'Checking account',
            isActive: true,
          ),
          onTap: () {},
        ),
      ));

      expect(find.text('Checking account'), findsOneWidget);

      // The first Container in the tree is the rounded card; its background
      // color follows the isActive branch.
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, RealUnitColors.brand200);
    });

    testWidgets('isActive=false: bg is neutral200', (tester) async {
      await tester.pumpApp(_host(
        SellBankAccountListItem(
          account: const BankAccount(
            id: 1,
            iban: 'CH9300762011623852957',
            name: 'Old account',
          ),
        ),
      ));

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, RealUnitColors.neutral200);
    });

    testWidgets('renders the IBAN with the standard four-group formatting',
        (tester) async {
      await tester.pumpApp(_host(
        SellBankAccountListItem(
          account: const BankAccount(
            id: 1,
            iban: 'CH9300762011623852957',
            isActive: true,
          ),
          onTap: () {},
        ),
      ));

      // 'CH9300762011623852957' → 'CH93 0076 2011 6238 5295 7'.
      expect(find.text('CH93 0076 2011 6238 5295 7'), findsOneWidget);
    });

    testWidgets('isActive=true + onDelete provided: delete button visible + tappable',
        (tester) async {
      var deletes = 0;
      await tester.pumpApp(_host(
        SellBankAccountListItem(
          account: const BankAccount(
            id: 1,
            iban: 'CH9300762011623852957',
            isActive: true,
          ),
          onTap: () {},
          onDelete: () => deletes++,
        ),
      ));

      expect(find.byIcon(Icons.delete_outline_outlined), findsOneWidget);
      await tester.tap(find.byType(IconButton));
      await tester.pump();
      expect(deletes, 1);
    });

    testWidgets('inactive: tap on the body is a no-op (onTap is null)',
        (tester) async {
      var taps = 0;
      await tester.pumpApp(_host(
        SellBankAccountListItem(
          account: const BankAccount(
            id: 1,
            iban: 'CH9300762011623852957',
          ),
          onTap: () => taps++,
        ),
      ));

      await tester.tap(find.byType(SellBankAccountListItem));
      await tester.pump();

      // GestureDetector.onTap is gated on isActive, so the callback never fires.
      expect(taps, 0);
    });
  });
}
