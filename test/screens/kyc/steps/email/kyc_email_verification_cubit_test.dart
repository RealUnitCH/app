import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_auth_service.dart';
import 'package:realunit_wallet/screens/kyc/steps/email/cubits/email_verification/kyc_email_verification_cubit.dart';

class _MockAuthService extends Mock implements DFXAuthService {}

String _fakeJwt(int accountId) {
  final header = base64Url
      .encode(utf8.encode('{"alg":"HS256"}'))
      .replaceAll('=', '');
  final payload = base64Url
      .encode(utf8.encode('{"account":$accountId}'))
      .replaceAll('=', '');
  return '$header.$payload.signature';
}

void main() {
  late _MockAuthService auth;

  setUp(() {
    auth = _MockAuthService();
    when(() => auth.invalidateAuthToken()).thenReturn(null);
  });

  KycEmailVerificationCubit build() =>
      KycEmailVerificationCubit(dfxService: auth);

  group('initial state', () {
    test('emits $KycEmailVerificationInitial', () {
      expect(build().state, isA<KycEmailVerificationInitial>());
    });
  });

  group('checkEmailVerification', () {
    blocTest<KycEmailVerificationCubit, KycEmailVerificationState>(
      'same account id before + after invalidation → Failure '
      '(confirmation link not visited yet)',
      setUp: () {
        // Both reads return the same token, so the same account id is parsed.
        when(() => auth.getAuthToken()).thenAnswer((_) async => _fakeJwt(1));
      },
      build: build,
      act: (c) => c.checkEmailVerification(),
      expect: () => [
        isA<KycEmailVerificationLoading>(),
        isA<KycEmailVerificationFailure>(),
      ],
      verify: (_) => verify(() => auth.invalidateAuthToken()).called(1),
    );

    blocTest<KycEmailVerificationCubit, KycEmailVerificationState>(
      'changed account id → Success (merge confirmed; the KYC flow handles '
      'registration — nothing is registered here)',
      setUp: () {
        final tokens = [_fakeJwt(1), _fakeJwt(2)];
        var i = 0;
        when(() => auth.getAuthToken()).thenAnswer((_) async => tokens[i++]);
      },
      build: build,
      act: (c) => c.checkEmailVerification(),
      expect: () => [
        isA<KycEmailVerificationLoading>(),
        isA<KycEmailVerificationSuccess>(),
      ],
    );

    blocTest<KycEmailVerificationCubit, KycEmailVerificationState>(
      'retry: first tap (link not visited) → Failure, second tap (account now '
      'changed) → Success',
      setUp: () {
        // tap 1: both reads = account 1 → Failure.
        // tap 2: account 1 → 2 → Success.
        final tokens = [_fakeJwt(1), _fakeJwt(1), _fakeJwt(1), _fakeJwt(2)];
        var i = 0;
        when(() => auth.getAuthToken()).thenAnswer((_) async => tokens[i++]);
      },
      build: build,
      act: (c) async {
        await c.checkEmailVerification();
        await c.checkEmailVerification();
      },
      expect: () => [
        isA<KycEmailVerificationLoading>(),
        isA<KycEmailVerificationFailure>(),
        isA<KycEmailVerificationLoading>(),
        isA<KycEmailVerificationSuccess>(),
      ],
    );
  });

  group('getAccountId', () {
    test('returns null when there is no token', () async {
      when(() => auth.getAuthToken()).thenAnswer((_) async => null);

      expect(await build().getAccountId(), isNull);
    });

    test('returns the account claim from a valid JWT', () async {
      when(() => auth.getAuthToken()).thenAnswer((_) async => _fakeJwt(42));

      expect(await build().getAccountId(), 42);
    });
  });
}
