import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_idensic_mobile_sdk_plugin/flutter_idensic_mobile_sdk_plugin.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/kyc/steps/ident/cubits/kyc_ident/kyc_ident_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/ident/cubits/kyc_ident/sumsub_ident_port.dart';

/// Programmable in-memory fake of [SumsubIdentPort]. Each test arms it with
/// the SDK outcome it wants to assert against — either a terminal
/// [SNSMobileSDKResult] or an exception — and the cubit consumes it like the
/// real adapter would.
class _FakeSumsubIdentPort implements SumsubIdentPort {
  _FakeSumsubIdentPort.result(SNSMobileSDKResult result) : _result = result, _error = null;
  _FakeSumsubIdentPort.error(Object error) : _result = null, _error = error;

  final SNSMobileSDKResult? _result;
  final Object? _error;

  String? capturedToken;
  String? capturedLocale;
  int launchCalls = 0;

  @override
  Future<SNSMobileSDKResult> launch({
    required String token,
    required String localeCode,
  }) async {
    launchCalls++;
    capturedToken = token;
    capturedLocale = localeCode;
    if (_error != null) {
      throw _error;
    }
    return _result!;
  }
}

SNSMobileSDKResult _resultWithStatus(SNSMobileSDKStatus status) =>
    SNSMobileSDKResult(true, status, null, null);

void main() {
  group('$KycIdentCubit', () {
    test('starts in $KycIdentInitial', () {
      final cubit = KycIdentCubit(
        identPort: _FakeSumsubIdentPort.result(
          _resultWithStatus(SNSMobileSDKStatus.Approved),
        ),
      );

      expect(cubit.state, const KycIdentInitial());
    });

    group('startIdent — terminal SDK status mapping', () {
      blocTest<KycIdentCubit, KycIdentState>(
        'Approved -> Loading, Success',
        build: () => KycIdentCubit(
          identPort: _FakeSumsubIdentPort.result(
            _resultWithStatus(SNSMobileSDKStatus.Approved),
          ),
        ),
        act: (cubit) => cubit.startIdent('access-token'),
        expect: () => const <KycIdentState>[
          KycIdentLoading(),
          KycIdentSuccess(),
        ],
      );

      blocTest<KycIdentCubit, KycIdentState>(
        'ActionCompleted -> Loading, Success',
        build: () => KycIdentCubit(
          identPort: _FakeSumsubIdentPort.result(
            _resultWithStatus(SNSMobileSDKStatus.ActionCompleted),
          ),
        ),
        act: (cubit) => cubit.startIdent('access-token'),
        expect: () => const <KycIdentState>[
          KycIdentLoading(),
          KycIdentSuccess(),
        ],
      );

      blocTest<KycIdentCubit, KycIdentState>(
        'Pending -> Loading, Success (web parity: pending is acceptance)',
        build: () => KycIdentCubit(
          identPort: _FakeSumsubIdentPort.result(
            _resultWithStatus(SNSMobileSDKStatus.Pending),
          ),
        ),
        act: (cubit) => cubit.startIdent('access-token'),
        expect: () => const <KycIdentState>[
          KycIdentLoading(),
          KycIdentSuccess(),
        ],
      );

      blocTest<KycIdentCubit, KycIdentState>(
        'FinallyRejected -> Loading, Failure(finallyRejected)',
        build: () => KycIdentCubit(
          identPort: _FakeSumsubIdentPort.result(
            _resultWithStatus(SNSMobileSDKStatus.FinallyRejected),
          ),
        ),
        act: (cubit) => cubit.startIdent('access-token'),
        expect: () => const <KycIdentState>[
          KycIdentLoading(),
          KycIdentFailure(status: FailureStatus.finallyRejected),
        ],
      );

      blocTest<KycIdentCubit, KycIdentState>(
        'TemporarilyDeclined -> Loading, Failure(temporarilyDeclined)',
        build: () => KycIdentCubit(
          identPort: _FakeSumsubIdentPort.result(
            _resultWithStatus(SNSMobileSDKStatus.TemporarilyDeclined),
          ),
        ),
        act: (cubit) => cubit.startIdent('access-token'),
        expect: () => const <KycIdentState>[
          KycIdentLoading(),
          KycIdentFailure(status: FailureStatus.temporarilyDeclined),
        ],
      );

      blocTest<KycIdentCubit, KycIdentState>(
        'Failed -> Loading, Failure(failed)',
        build: () => KycIdentCubit(
          identPort: _FakeSumsubIdentPort.result(
            _resultWithStatus(SNSMobileSDKStatus.Failed),
          ),
        ),
        act: (cubit) => cubit.startIdent('access-token'),
        expect: () => const <KycIdentState>[
          KycIdentLoading(),
          KycIdentFailure(status: FailureStatus.failed),
        ],
      );
    });

    group('startIdent — non-terminal SDK statuses collapse to Initial', () {
      blocTest<KycIdentCubit, KycIdentState>(
        'Incomplete -> Loading, Initial (user cancelled mid-flow)',
        build: () => KycIdentCubit(
          identPort: _FakeSumsubIdentPort.result(
            _resultWithStatus(SNSMobileSDKStatus.Incomplete),
          ),
        ),
        act: (cubit) => cubit.startIdent('access-token'),
        expect: () => const <KycIdentState>[
          KycIdentLoading(),
          KycIdentInitial(),
        ],
      );

      blocTest<KycIdentCubit, KycIdentState>(
        'Initial -> Loading, Initial (flow never progressed)',
        build: () => KycIdentCubit(
          identPort: _FakeSumsubIdentPort.result(
            _resultWithStatus(SNSMobileSDKStatus.Initial),
          ),
        ),
        act: (cubit) => cubit.startIdent('access-token'),
        expect: () => const <KycIdentState>[
          KycIdentLoading(),
          KycIdentInitial(),
        ],
      );

      blocTest<KycIdentCubit, KycIdentState>(
        'Ready -> Loading, Initial (SDK initialised but no user action)',
        build: () => KycIdentCubit(
          identPort: _FakeSumsubIdentPort.result(
            _resultWithStatus(SNSMobileSDKStatus.Ready),
          ),
        ),
        act: (cubit) => cubit.startIdent('access-token'),
        expect: () => const <KycIdentState>[
          KycIdentLoading(),
          KycIdentInitial(),
        ],
      );
    });

    group('startIdent — error path', () {
      blocTest<KycIdentCubit, KycIdentState>(
        'SDK throws -> Loading, Failure(error) with errorMessage',
        build: () => KycIdentCubit(
          identPort: _FakeSumsubIdentPort.error(
            Exception('Token expired. Please open a new ident session to get a new token.'),
          ),
        ),
        act: (cubit) => cubit.startIdent('access-token'),
        expect: () => <KycIdentState>[
          const KycIdentLoading(),
          const KycIdentFailure(
            status: FailureStatus.error,
            errorMessage:
                'Exception: Token expired. Please open a new ident session to get a new token.',
          ),
        ],
      );

      blocTest<KycIdentCubit, KycIdentState>(
        'arbitrary non-Exception throwable -> Failure(error) with stringified message',
        build: () => KycIdentCubit(
          identPort: _FakeSumsubIdentPort.error('boom'),
        ),
        act: (cubit) => cubit.startIdent('access-token'),
        expect: () => <KycIdentState>[
          const KycIdentLoading(),
          const KycIdentFailure(
            status: FailureStatus.error,
            errorMessage: 'boom',
          ),
        ],
      );
    });

    group('startIdent — port wiring', () {
      test('forwards token and explicit locale to the port', () async {
        final port = _FakeSumsubIdentPort.result(
          _resultWithStatus(SNSMobileSDKStatus.Approved),
        );
        final cubit = KycIdentCubit(identPort: port);

        await cubit.startIdent('my-token', localeCode: 'de');

        expect(port.launchCalls, 1);
        expect(port.capturedToken, 'my-token');
        expect(port.capturedLocale, 'de');
      });

      test("defaults localeCode to 'en' when caller omits it", () async {
        final port = _FakeSumsubIdentPort.result(
          _resultWithStatus(SNSMobileSDKStatus.Approved),
        );
        final cubit = KycIdentCubit(identPort: port);

        await cubit.startIdent('my-token');

        expect(port.capturedLocale, 'en');
      });
    });
  });

  group('$KycIdentFailure', () {
    test('equality is driven by status + errorMessage (Equatable contract)', () {
      const a = KycIdentFailure(status: FailureStatus.error, errorMessage: 'x');
      const b = KycIdentFailure(status: FailureStatus.error, errorMessage: 'x');
      const c = KycIdentFailure(status: FailureStatus.failed, errorMessage: 'x');
      const d = KycIdentFailure(status: FailureStatus.error, errorMessage: 'y');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a, isNot(equals(d)));
    });
  });
}
