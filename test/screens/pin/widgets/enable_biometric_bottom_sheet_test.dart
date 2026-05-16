import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/pin/widgets/enable_biometric_bottom_sheet.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';
import 'package:realunit_wallet/widgets/buttons/app_text_button.dart';

import '../../../helper/helper.dart';

void main() {
  group('$EnableBiometricBottomSheet', () {
    testWidgets('renders the fingerprint icon (blue, size 64)', (tester) async {
      await tester.pumpApp(const EnableBiometricBottomSheet());

      final icon = tester.widget<Icon>(find.byIcon(Icons.fingerprint));
      expect(icon.color, RealUnitColors.realUnitBlue);
      expect(icon.size, 64);
    });

    testWidgets('renders an AppFilledButton (Enable) + AppTextButton (Skip)',
        (tester) async {
      await tester.pumpApp(const EnableBiometricBottomSheet());

      expect(find.byType(AppFilledButton), findsOneWidget);
      expect(find.byType(AppTextButton), findsOneWidget);
    });

    testWidgets('Enable button has a non-null onPressed callback', (tester) async {
      await tester.pumpApp(const EnableBiometricBottomSheet());

      final button = tester.widget<AppFilledButton>(find.byType(AppFilledButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('Skip button has a non-null onPressed callback', (tester) async {
      await tester.pumpApp(const EnableBiometricBottomSheet());

      final button = tester.widget<AppTextButton>(find.byType(AppTextButton));
      expect(button.onPressed, isNotNull);
    });
  });
}
