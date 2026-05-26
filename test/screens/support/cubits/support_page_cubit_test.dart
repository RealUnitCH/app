import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_level.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/dto/user_dto.dart';
import 'package:realunit_wallet/screens/support/cubits/support_page/support_page_cubit.dart';

class _MockKycService extends Mock implements DfxKycService {}

UserDto _userWith({String? mail}) => UserDto(
  mail: mail,
  kyc: const UserKycDto(
    hash: 'h',
    level: KycLevel.level0,
    dataComplete: false,
  ),
);

void main() {
  late _MockKycService kycService;

  setUp(() {
    kycService = _MockKycService();
  });

  group('$SupportPageCubit', () {
    test('initial state is SupportPageIdle', () {
      final cubit = SupportPageCubit(kycService);
      expect(cubit.state, isA<SupportPageIdle>());
    });

    blocTest<SupportPageCubit, SupportPageState>(
      'requestCreateTicket with mail present emits Navigating + NavigateToCreate',
      build: () => SupportPageCubit(kycService),
      setUp: () {
        when(
          () => kycService.getUser(),
        ).thenAnswer((_) async => _userWith(mail: 'user@example.com'));
      },
      act: (cubit) => cubit.requestCreateTicket(),
      expect: () => [
        isA<SupportPageNavigating>(),
        isA<SupportPageNavigateToCreate>(),
      ],
      verify: (_) {
        verify(() => kycService.getUser()).called(1);
      },
    );

    blocTest<SupportPageCubit, SupportPageState>(
      'requestCreateTicket with null mail emits Navigating + NavigateToEmailThenCreate',
      build: () => SupportPageCubit(kycService),
      setUp: () {
        when(() => kycService.getUser()).thenAnswer((_) async => _userWith(mail: null));
      },
      act: (cubit) => cubit.requestCreateTicket(),
      expect: () => [
        isA<SupportPageNavigating>(),
        isA<SupportPageNavigateToEmailThenCreate>(),
      ],
    );

    blocTest<SupportPageCubit, SupportPageState>(
      'requestCreateTicket with empty-string mail does NOT trigger the email gate',
      // The DTO models mail as `String?` — only `null` represents "not on
      // record". Pinning this prevents an accidental future drift toward
      // `mail.isEmpty == true` treating "" as missing, which would
      // contradict the API contract where the backend itself decides.
      build: () => SupportPageCubit(kycService),
      setUp: () {
        when(() => kycService.getUser()).thenAnswer((_) async => _userWith(mail: ''));
      },
      act: (cubit) => cubit.requestCreateTicket(),
      expect: () => [
        isA<SupportPageNavigating>(),
        isA<SupportPageNavigateToCreate>(),
      ],
    );

    blocTest<SupportPageCubit, SupportPageState>(
      'requestCreateTicket emits NavigationFailure when getUser throws',
      build: () => SupportPageCubit(kycService),
      setUp: () {
        when(() => kycService.getUser()).thenThrow(Exception('network down'));
      },
      act: (cubit) => cubit.requestCreateTicket(),
      expect: () => [
        isA<SupportPageNavigating>(),
        predicate<SupportPageNavigationFailure>(
          (s) => s.message.contains('network down'),
          'NavigationFailure carries the thrown message',
        ),
      ],
    );

    blocTest<SupportPageCubit, SupportPageState>(
      'requestCreateTicket surfaces the API-level message verbatim on ApiException',
      // Mirrors `SupportEmailCaptureCubit.submit()` — typed `ApiException`
      // path must use `e.message` not `e.toString()`, otherwise the user
      // sees a cryptic snackbar like
      // `RealUnitApiException: BAD_REQUEST (code: BAD_REQUEST, statusCode: 400)`
      // instead of the human-readable backend message.
      build: () => SupportPageCubit(kycService),
      setUp: () {
        when(() => kycService.getUser()).thenThrow(
          const ApiException(
            statusCode: 400,
            code: 'BAD_REQUEST',
            message: 'user lookup failed',
          ),
        );
      },
      act: (cubit) => cubit.requestCreateTicket(),
      expect: () => [
        isA<SupportPageNavigating>(),
        predicate<SupportPageNavigationFailure>(
          (s) => s.message == 'user lookup failed',
          'NavigationFailure surfaces the ApiException message, not toString()',
        ),
      ],
    );

    test('requestCreateTicket() is a no-op while already navigating', () async {
      // Documents the re-entry guard: a programmatic second call (or a
      // sufficiently fast double-tap that beats the view's onTap disable)
      // while a getUser() fetch is still in flight must not start a
      // parallel API call. We use a Completer to keep the first call
      // hanging so the cubit stays in `Navigating` for the second
      // invocation.
      final completer = Completer<UserDto>();
      when(() => kycService.getUser()).thenAnswer((_) => completer.future);

      final cubit = SupportPageCubit(kycService);
      addTearDown(cubit.close);

      // Fire the first call; do NOT await — the future is intentionally
      // pending.
      // ignore: unawaited_futures
      cubit.requestCreateTicket();
      // Give the cubit a microtask turn so it has transitioned to
      // `Navigating` before the second invocation.
      await Future<void>.value();
      expect(cubit.state, isA<SupportPageNavigating>());

      // Second invocation must early-return without touching the service
      // again.
      await cubit.requestCreateTicket();

      verify(() => kycService.getUser()).called(1);
      verifyNoMoreInteractions(kycService);

      // Release the first call so the cubit can settle; not strictly
      // required for the assertion above but keeps the test free of
      // unfinished microtasks.
      completer.complete(_userWith(mail: 'user@example.com'));
      await Future<void>.delayed(Duration.zero);
    });

    blocTest<SupportPageCubit, SupportPageState>(
      'acknowledge emits Idle from any non-idle state',
      build: () => SupportPageCubit(kycService),
      seed: () => const SupportPageNavigateToCreate(),
      act: (cubit) => cubit.acknowledge(),
      expect: () => [isA<SupportPageIdle>()],
    );
  });
}
