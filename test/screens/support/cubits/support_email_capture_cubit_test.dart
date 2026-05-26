import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_email_status.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';
import 'package:realunit_wallet/screens/support/cubits/support_email_capture/support_email_capture_cubit.dart';

class _MockRegistrationService extends Mock implements RealUnitRegistrationService {}

void main() {
  late _MockRegistrationService service;

  setUp(() {
    service = _MockRegistrationService();
  });

  group('$SupportEmailCaptureCubit', () {
    test('initial state is SupportEmailCaptureInitial', () {
      final cubit = SupportEmailCaptureCubit(service);
      expect(cubit.state, isA<SupportEmailCaptureInitial>());
    });

    blocTest<SupportEmailCaptureCubit, SupportEmailCaptureState>(
      'submit emits Submitting + Success on registerEmail success',
      build: () => SupportEmailCaptureCubit(service),
      setUp: () {
        when(
          () => service.registerEmail(any()),
        ).thenAnswer((_) async => RegistrationEmailStatus.emailRegistered);
      },
      act: (cubit) => cubit.submit('user@example.com'),
      expect: () => [
        isA<SupportEmailCaptureSubmitting>(),
        isA<SupportEmailCaptureSuccess>(),
      ],
      verify: (_) {
        verify(() => service.registerEmail('user@example.com')).called(1);
      },
    );

    blocTest<SupportEmailCaptureCubit, SupportEmailCaptureState>(
      'submit forwards the API-level message verbatim on ApiException',
      build: () => SupportEmailCaptureCubit(service),
      setUp: () {
        when(() => service.registerEmail(any())).thenThrow(
          const ApiException(
            statusCode: 400,
            code: 'BAD_REQUEST',
            message: 'email already in use',
          ),
        );
      },
      act: (cubit) => cubit.submit('user@example.com'),
      expect: () => [
        isA<SupportEmailCaptureSubmitting>(),
        predicate<SupportEmailCaptureFailure>(
          (s) => s.message == 'email already in use',
          'Failure surfaces the ApiException message, not the full toString()',
        ),
      ],
    );

    blocTest<SupportEmailCaptureCubit, SupportEmailCaptureState>(
      'submit falls back to toString() on generic throw',
      build: () => SupportEmailCaptureCubit(service),
      setUp: () {
        when(() => service.registerEmail(any())).thenThrow(Exception('socket timeout'));
      },
      act: (cubit) => cubit.submit('user@example.com'),
      expect: () => [
        isA<SupportEmailCaptureSubmitting>(),
        predicate<SupportEmailCaptureFailure>(
          (s) => s.message.contains('socket timeout'),
          'Failure carries the underlying exception text',
        ),
      ],
    );
  });
}
