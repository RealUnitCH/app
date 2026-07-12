import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/models/wallet/real_unit_registration_info_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/wallet/real_unit_registration_state.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';
import 'package:realunit_wallet/screens/kyc/steps/confirm_email/cubits/kyc_confirm_email_cubit.dart';

class _MockRealUnitRegistrationService extends Mock
    implements RealUnitRegistrationService {}

RealUnitRegistrationInfoDto _info({bool? emailConfirmed}) =>
    RealUnitRegistrationInfoDto(
      state: RealUnitRegistrationState.alreadyRegistered,
      emailConfirmed: emailConfirmed,
    );

void main() {
  late _MockRealUnitRegistrationService registrationService;

  setUp(() {
    registrationService = _MockRealUnitRegistrationService();
  });

  KycConfirmEmailCubit build() => KycConfirmEmailCubit(registrationService);

  group('initial state', () {
    test('is $KycConfirmEmailInitial', () {
      expect(build().state, isA<KycConfirmEmailInitial>());
    });
  });

  group('recheck', () {
    blocTest<KycConfirmEmailCubit, KycConfirmEmailState>(
      'emailConfirmed=false → NotConfirmed (stays on the gate)',
      setUp: () {
        when(() => registrationService.getRegistrationInfo()).thenAnswer(
          (_) async => _info(emailConfirmed: false),
        );
      },
      build: build,
      act: (c) => c.recheck(),
      expect: () => [
        isA<KycConfirmEmailLoading>(),
        isA<KycConfirmEmailNotConfirmed>(),
      ],
    );

    blocTest<KycConfirmEmailCubit, KycConfirmEmailState>(
      'emailConfirmed=true → Confirmed (proceeds)',
      setUp: () {
        when(() => registrationService.getRegistrationInfo()).thenAnswer(
          (_) async => _info(emailConfirmed: true),
        );
      },
      build: build,
      act: (c) => c.recheck(),
      expect: () => [
        isA<KycConfirmEmailLoading>(),
        isA<KycConfirmEmailConfirmed>(),
      ],
    );

    blocTest<KycConfirmEmailCubit, KycConfirmEmailState>(
      'emailConfirmed=null (legacy / no gate) → Confirmed (proceeds)',
      setUp: () {
        when(() => registrationService.getRegistrationInfo()).thenAnswer(
          (_) async => _info(),
        );
      },
      build: build,
      act: (c) => c.recheck(),
      expect: () => [
        isA<KycConfirmEmailLoading>(),
        isA<KycConfirmEmailConfirmed>(),
      ],
    );

    blocTest<KycConfirmEmailCubit, KycConfirmEmailState>(
      'getRegistrationInfo throws → NotConfirmed (fail closed, retryable)',
      setUp: () {
        when(() => registrationService.getRegistrationInfo()).thenThrow(
          Exception('network error'),
        );
      },
      build: build,
      act: (c) => c.recheck(),
      expect: () => [
        isA<KycConfirmEmailLoading>(),
        isA<KycConfirmEmailNotConfirmed>(),
      ],
    );

    blocTest<KycConfirmEmailCubit, KycConfirmEmailState>(
      'retry: still-false then flips-true → NotConfirmed, then Confirmed',
      setUp: () {
        final answers = [_info(emailConfirmed: false), _info(emailConfirmed: true)];
        var i = 0;
        when(() => registrationService.getRegistrationInfo()).thenAnswer(
          (_) async => answers[i++],
        );
      },
      build: build,
      act: (c) async {
        await c.recheck();
        await c.recheck();
      },
      expect: () => [
        isA<KycConfirmEmailLoading>(),
        isA<KycConfirmEmailNotConfirmed>(),
        isA<KycConfirmEmailLoading>(),
        isA<KycConfirmEmailConfirmed>(),
      ],
    );

    // A stalled request (socket up, backend never responds) must not wedge
    // the button in its loading state forever. `recheck()` watch-dogs the
    // call with a 30s timeout; the resulting `TimeoutException` fails closed
    // to NotConfirmed (retryable). fake_async advances virtual time past the
    // budget without a wallclock sleep. Mirrors the `KycCubit` outer-timeout
    // test.
    test(
      'stalled getRegistrationInfo -> NotConfirmed after the timeout (not stuck loading)',
      () {
        fakeAsync((async) {
          when(() => registrationService.getRegistrationInfo()).thenAnswer(
            (_) => Completer<RealUnitRegistrationInfoDto>().future,
          );

          final cubit = build();
          final states = <KycConfirmEmailState>[];
          final sub = cubit.stream.listen(states.add);

          unawaited(cubit.recheck());
          async.elapse(const Duration(seconds: 31));

          expect(states, const [
            KycConfirmEmailLoading(),
            KycConfirmEmailNotConfirmed(),
          ]);

          sub.cancel();
          cubit.close();
        });
      },
    );
  });
}
