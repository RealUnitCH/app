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
  });
}
