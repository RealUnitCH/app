import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/walletconnect/walletconnect_allowlist.dart';

void main() {
  group('WalletConnectAllowlist', () {
    test('allows Aktionariat and Frankencoin hosts including subdomains', () {
      expect(
        WalletConnectAllowlist.isAllowedOrigin('https://tokeninfo.aktionariat.com/realunit'),
        isTrue,
      );
      expect(WalletConnectAllowlist.isAllowedOrigin('https://aktionariat.com'), isTrue);
      expect(WalletConnectAllowlist.isAllowedOrigin('https://www.aktionariat.com'), isTrue);
      expect(WalletConnectAllowlist.isAllowedOrigin('https://app.frankencoin.com'), isTrue);
      expect(WalletConnectAllowlist.isAllowedOrigin('https://frankencoin.com'), isTrue);
      expect(WalletConnectAllowlist.isAllowedOrigin('https://shares.realunit.ch'), isTrue);
      expect(
        WalletConnectAllowlist.isAllowedOrigin('https://tokeninfo.aktionariat.com.'),
        isTrue,
      );
    });

    test('rejects other providers including etherscan', () {
      expect(WalletConnectAllowlist.isAllowedOrigin('https://etherscan.io'), isFalse);
      expect(WalletConnectAllowlist.isAllowedOrigin('https://etherscan.com'), isFalse);
      expect(
        WalletConnectAllowlist.isAllowedOrigin('https://aktionariat.com.evil.com'),
        isFalse,
      );
      expect(WalletConnectAllowlist.isAllowedOrigin('https://notaktionariat.com'), isFalse);
      expect(WalletConnectAllowlist.isAllowedOrigin(null), isFalse);
      expect(WalletConnectAllowlist.isAllowedOrigin(''), isFalse);
    });

    test('rejects http schemes even for allowlisted hosts', () {
      expect(WalletConnectAllowlist.isAllowedOrigin('http://aktionariat.com'), isFalse);
      expect(WalletConnectAllowlist.isAllowedOrigin('http://shares.realunit.ch'), isFalse);
    });

    test('rejects scheme-relative URLs even for allowlisted hosts', () {
      expect(WalletConnectAllowlist.isAllowedOrigin('//aktionariat.com'), isFalse);
      expect(WalletConnectAllowlist.isAllowedOrigin('//shares.realunit.ch'), isFalse);
      expect(WalletConnectAllowlist.isAllowedOrigin('//app.frankencoin.com'), isFalse);
    });

    test('rejects non-https schemes that would otherwise prepend onto the host', () {
      expect(WalletConnectAllowlist.isAllowedOrigin('mailto:x@aktionariat.com'), isFalse);
      expect(WalletConnectAllowlist.isAllowedOrigin('javascript:aktionariat.com'), isFalse);
    });

    test('accepts https subdomain and bare host (prepended to https)', () {
      expect(
        WalletConnectAllowlist.isAllowedOrigin('https://tokeninfo.aktionariat.com'),
        isTrue,
      );
      expect(
        WalletConnectAllowlist.isAllowedOrigin('tokeninfo.aktionariat.com'),
        isTrue,
      );
    });
  });
}
