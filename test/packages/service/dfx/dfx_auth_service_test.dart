import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_auth_service.dart';
import 'package:realunit_wallet/packages/service/session_cache.dart';
import 'package:realunit_wallet/packages/wallet/exceptions/signing_cancelled_exception.dart';
import 'package:realunit_wallet/packages/wallet/wallet_account.dart';
import 'package:web3dart/web3dart.dart';

class _MockAppStore extends Mock implements AppStore {}

class _MockSessionCache extends Mock implements SessionCache {}

class _StubWalletAccount extends AWalletAccount {
  _StubWalletAccount(this._signature)
    : super(
        0,
        EthPrivateKey.fromHex(
          'fb1ace12f9801e85f3db1b3935dd47d9f064f98152466f47c701b5e12680e612',
        ),
      );

  final String _signature;
  int signCallCount = 0;

  @override
  Future<String> signMessage(String message, {int addressIndex = 0}) async {
    signCallCount++;
    return _signature;
  }
}

class _TestAuthService extends DFXAuthService {
  _TestAuthService(super.appStore, this._wallet, this._address);

  final AWalletAccount _wallet;
  final String _address;

  @override
  AWalletAccount get wallet => _wallet;

  @override
  String get walletAddress => _address;
}

void main() {
  late AppStore appStore;
  late SessionCache sessionCache;
  late _StubWalletAccount walletAccount;

  const address = '0x1111111111111111111111111111111111111111';
  const validSig = '0xdeadbeef';

  setUp(() {
    appStore = _MockAppStore();
    sessionCache = _MockSessionCache();
    walletAccount = _StubWalletAccount(validSig);

    when(() => appStore.sessionCache).thenReturn(sessionCache);
    when(() => sessionCache.signature).thenReturn(null);
    when(() => sessionCache.signatureAddress).thenReturn(null);
    when(() => sessionCache.authToken).thenReturn(null);
    when(() => sessionCache.saveSignature(any(), any())).thenAnswer((_) async {});
  });

  _TestAuthService buildService() => _TestAuthService(appStore, walletAccount, address);

  group('$DFXAuthService getSignature', () {
    test('returns the cached signature when address matches (no re-sign)', () async {
      when(() => sessionCache.signature).thenReturn(validSig);
      when(() => sessionCache.signatureAddress).thenReturn(address);

      final result = await buildService().getSignature('msg');

      expect(result, validSig);
      expect(walletAccount.signCallCount, 0);
      verifyNever(() => sessionCache.saveSignature(any(), any()));
    });

    test('signs and caches when no cached signature exists', () async {
      final result = await buildService().getSignature('msg');

      expect(result, validSig);
      expect(walletAccount.signCallCount, 1);
      verify(() => sessionCache.saveSignature(address, validSig)).called(1);
    });

    test('signs again when the cached signature belongs to a different address', () async {
      when(() => sessionCache.signature).thenReturn(validSig);
      when(() => sessionCache.signatureAddress).thenReturn(
        '0x2222222222222222222222222222222222222222',
      );

      final result = await buildService().getSignature('msg');

      expect(result, validSig);
      expect(walletAccount.signCallCount, 1);
    });

    for (final emptySignature in const ['', '0x']) {
      test(
        'throws SigningCancelledException when the wallet returns "$emptySignature"',
        () async {
          walletAccount = _StubWalletAccount(emptySignature);

          expect(
            () => buildService().getSignature('msg'),
            throwsA(isA<SigningCancelledException>()),
          );
        },
      );
    }
  });

  group('$DFXAuthService getAuthToken', () {
    test('returns the cached auth token without re-signing', () async {
      when(() => sessionCache.authToken).thenReturn('cached.jwt.token');

      final token = await buildService().getAuthToken();

      expect(token, 'cached.jwt.token');
      expect(walletAccount.signCallCount, 0);
    });
  });

  // TODO(#314 Phase 0): cover the 3 min `_signMessageTimeout` via the
  // `fake_async` package. Not yet a dev_dependency in this repo — adding it
  // would require a follow-up. Captured here as an explicit gap.
}
