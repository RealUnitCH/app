import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:realunit_wallet/screens/receive/widgets/qr_address_widget.dart';

const _address = '0x9F5713DEacB8e9CAB6c2d3FaE1AFc2715F8D2D71';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('$QRAddressWidget', () {
    testWidgets('renders a QrImageView for the uri', (tester) async {
      await tester.pumpWidget(_host(
        QRAddressWidget(uri: 'ethereum:$_address', subtitle: _address),
      ));

      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('renders the address as one Text.rich containing all chunks',
        (tester) async {
      await tester.pumpWidget(_host(
        QRAddressWidget(uri: '', subtitle: _address),
      ));

      // RichText is rendered with concatenated text — find.textContaining
      // walks descendants, hitting the rendered TextSpan tree.
      expect(find.textContaining(_address.substring(0, 6)), findsAtLeastNWidgets(1));
      expect(find.textContaining(_address.substring(36)), findsAtLeastNWidgets(1));
    });

    testWidgets('renders a copy icon next to the address', (tester) async {
      await tester.pumpWidget(_host(
        QRAddressWidget(uri: '', subtitle: _address),
      ));

      expect(find.byIcon(Icons.copy_outlined), findsOneWidget);
    });

    testWidgets('tapping the address row is wrapped in a tappable InkWell',
        (tester) async {
      await tester.pumpWidget(_host(
        QRAddressWidget(uri: '', subtitle: _address),
      ));

      // Tapping should not throw (clipboard plugin is no-op in test bindings).
      await tester.tap(find.byType(InkWell));
      await tester.pump();
    });
  });
}
