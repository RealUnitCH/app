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
      expect(
        WalletConnectUri.isPairingUri('wc:@2?relay-protocol=irn&symKey=0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef'),
        isFalse,
      );
    });

    test('extracts uri from an Android intent extra', () {
      final wrapped =
          'intent://wc?uri=${Uri.encodeComponent(pairing)}#Intent;scheme=wc;end';
      expect(WalletConnectUri.extractPairingUri(wrapped), pairing);
    });

    test('isWalletConnectInput accepts pairing, wrap, and scan links', () {
      expect(WalletConnectUri.isWalletConnectInput(pairing), isTrue);
      expect(
        WalletConnectUri.isWalletConnectInput(
          'realunit-wallet://wc?uri=${Uri.encodeComponent(pairing)}',
        ),
        isTrue,
      );
      expect(
        WalletConnectUri.isWalletConnectInput('realunit-wallet://investorpage'),
        isTrue,
      );
      expect(WalletConnectUri.isWalletConnectInput('https://etherscan.io'), isFalse);
    });

    test('opaque investorpage without host is a scan deeplink', () {
      expect(WalletConnectUri.isScanDeeplink('realunit-wallet:investorpage'), isTrue);
    });

    test('treats an Android intent investorpage wrapper as a scan deeplink', () {
      expect(
        WalletConnectUri.isScanDeeplink(
          'intent://investorpage/REALU#Intent;scheme=realunit-wallet;end',
        ),
        isTrue,
      );
    });

    test('extracts uri from an intent fragment S.uri extra', () {
      final wrapped =
          'intent://wc#Intent;scheme=wc;S.uri=${Uri.encodeComponent(pairing)};end';
      expect(WalletConnectUri.extractPairingUri(wrapped), pairing);
    });

    test('returns null when the nested uri is not a pairing URI', () {
      expect(
        WalletConnectUri.extractPairingUri('realunit-wallet://wc?uri=hello'),
        isNull,
      );
    });

    test('returns null when the nested uri is malformed percent-encoding', () {
      expect(
        WalletConnectUri.extractPairingUri('realunit-wallet://wc?uri=%'),
        isNull,
      );
    });
  });
}
