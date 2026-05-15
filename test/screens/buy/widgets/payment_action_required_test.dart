import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/buy/widgets/payment_action_required.dart';
import 'package:realunit_wallet/styles/colors.dart';

void main() {
  group('$PaymentActionRequired', () {
    testWidgets('renders title + description + info icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PaymentActionRequired(
              title: 'KYC required',
              description: 'Please complete identity verification.',
            ),
          ),
        ),
      );

      expect(find.text('KYC required'), findsOneWidget);
      expect(find.text('Please complete identity verification.'), findsOneWidget);
      expect(find.byIcon(Icons.info), findsOneWidget);
    });

    testWidgets('icon carries the RealUnit blue brand color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PaymentActionRequired(
              title: 't',
              description: 'd',
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.info));
      expect(icon.color, RealUnitColors.realUnitBlue);
      expect(icon.size, 24);
    });
  });
}
