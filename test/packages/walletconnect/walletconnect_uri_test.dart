import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/walletconnect/walletconnect_uri.dart';

const pairing =
    'wc:00e46b69-d0cc-4b3e-b6a2-cee442f97188@2?relay-protocol=irn&symKey=0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

void main() {
  group('WalletConnectUri', () {
    test('accepts v2 pairing URIs', () {
      expect(WalletConnectUri.isPairingUri(pairing), isTrue);
      expect(WalletConnectUri.extractPairingUri(pairing), pairing);
    });

    test('extracts uri from realunit-wallet deeplink', () {
      final wrapped = 'realunit-wallet://wc?uri=${Uri.encodeComponent(pairing)}';
      expect(WalletConnectUri.extractPairingUri(wrapped), pairing);
    });

    test('treats investorpage as scan deeplink not pairing', () {
      expect(
        WalletConnectUri.isScanDeeplink('realunit-wallet://investorpage/REALU'),
        isTrue,
      );
      expect(
        WalletConnectUri.extractPairingUri('realunit-wallet://investorpage/REALU'),
        isNull,
      );
    });

    test('rejects unrelated payloads', () {
      expect(WalletConnectUri.isPairingUri('ethereum:0xabc'), isFalse);
      expect(WalletConnectUri.extractPairingUri('https://etherscan.io'), isNull);
    });
  });
}
