import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/walletconnect/walletconnect_engine.dart';

void main() {
  group('mapWalletConnectVerify', () {
    test('VALID maps to valid', () {
      expect(
        mapWalletConnectVerify(isScam: false, validationName: 'VALID'),
        WalletConnectVerifyStatus.valid,
      );
    });

    test('INVALID maps to invalid', () {
      expect(
        mapWalletConnectVerify(isScam: false, validationName: 'INVALID'),
        WalletConnectVerifyStatus.invalid,
      );
    });

    test('UNKNOWN, null, and garbage map to unknown', () {
      expect(
        mapWalletConnectVerify(isScam: false, validationName: 'UNKNOWN'),
        WalletConnectVerifyStatus.unknown,
      );
      expect(
        mapWalletConnectVerify(isScam: false, validationName: null),
        WalletConnectVerifyStatus.unknown,
      );
      expect(
        mapWalletConnectVerify(isScam: false, validationName: 'not-a-status'),
        WalletConnectVerifyStatus.unknown,
      );
    });

    test('SCAM maps to scam', () {
      expect(
        mapWalletConnectVerify(isScam: false, validationName: 'SCAM'),
        WalletConnectVerifyStatus.scam,
      );
    });

    test('isScam true maps to scam for any validationName', () {
      expect(
        mapWalletConnectVerify(isScam: true, validationName: 'VALID'),
        WalletConnectVerifyStatus.scam,
      );
      expect(
        mapWalletConnectVerify(isScam: true, validationName: null),
        WalletConnectVerifyStatus.scam,
      );
    });

    test(
      'Validation.SCAM toString form must not become valid via substring match',
      () {
        expect(
          mapWalletConnectVerify(
            isScam: false,
            validationName: 'Validation.SCAM',
          ),
          WalletConnectVerifyStatus.unknown,
        );
      },
    );
  });

  group('attestedOriginUrl', () {
    test('returns trimmed Verify origin and drops empty', () {
      expect(attestedOriginUrl('https://tokeninfo.aktionariat.com'), 'https://tokeninfo.aktionariat.com');
      expect(attestedOriginUrl('  https://app.frankencoin.com  '), 'https://app.frankencoin.com');
      expect(attestedOriginUrl(null), isNull);
      expect(attestedOriginUrl(''), isNull);
      expect(attestedOriginUrl('   '), isNull);
    });
  });
}
