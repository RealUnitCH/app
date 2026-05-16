import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_email_status.dart';
import 'package:realunit_wallet/screens/kyc/steps/2fa/cubits/kyc_2fa/kyc_2fa_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/2fa/cubits/kyc_2fa_verify/kyc_2fa_verify_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/email/cubits/email_step/kyc_email_step_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/email/cubits/email_verification/kyc_email_verification_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/ident/cubits/kyc_ident/kyc_ident_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/nationality/cubit/kyc_nationality/kyc_nationality_cubit.dart';

void main() {
  group('$KycEmailStepState', () {
    test('Success props pin the wire status', () {
      expect(
        const KycEmailStepSuccess(RegistrationEmailStatus.emailRegistered),
        const KycEmailStepSuccess(RegistrationEmailStatus.emailRegistered),
      );
      expect(
        const KycEmailStepSuccess(RegistrationEmailStatus.emailRegistered),
        isNot(const KycEmailStepSuccess(RegistrationEmailStatus.mergeRequested)),
      );
    });

    test('KycEmailStepError enum has exactly emailDoesNotMatch + unknown', () {
      expect(KycEmailStepError.values.toSet(),
          {KycEmailStepError.emailDoesNotMatch, KycEmailStepError.unknown});
    });
  });

  group('$KycEmailVerificationState', () {
    test('all four states are distinct singletons by type', () {
      expect(const KycEmailVerificationInitial(), const KycEmailVerificationInitial());
      expect(const KycEmailVerificationInitial(),
          isNot(const KycEmailVerificationLoading()));
      expect(const KycEmailVerificationSuccess(),
          isNot(const KycEmailVerificationFailure()));
      expect(const KycEmailVerificationFailure(),
          isNot(const KycEmailVerificationRegistrationFailure()));
    });
  });

  group('$KycNationalityState', () {
    test('Failure props pin the message', () {
      expect(
        const KycNationalityFailure('boom'),
        const KycNationalityFailure('boom'),
      );
      expect(
        const KycNationalityFailure('boom'),
        isNot(const KycNationalityFailure('other')),
      );
    });
  });

  group('$KycIdentState', () {
    test('FailureStatus enum has all four variants', () {
      expect(FailureStatus.values.toSet(), {
        FailureStatus.error,
        FailureStatus.finallyRejected,
        FailureStatus.temporarilyDeclined,
        FailureStatus.failed,
      });
    });

    test('KycIdentFailure props pin (status, errorMessage)', () {
      expect(
        const KycIdentFailure(status: FailureStatus.error, errorMessage: 'x'),
        const KycIdentFailure(status: FailureStatus.error, errorMessage: 'x'),
      );
      expect(
        const KycIdentFailure(status: FailureStatus.error, errorMessage: 'x'),
        isNot(const KycIdentFailure(status: FailureStatus.failed, errorMessage: 'x')),
      );
      expect(
        const KycIdentFailure(status: FailureStatus.error, errorMessage: 'x'),
        isNot(const KycIdentFailure(status: FailureStatus.error, errorMessage: 'y')),
      );
    });
  });

  group('$Kyc2FaState', () {
    test('Failure props pin the errorMessage', () {
      expect(
        const Kyc2FaFailure(errorMessage: 'boom'),
        const Kyc2FaFailure(errorMessage: 'boom'),
      );
      expect(
        const Kyc2FaFailure(errorMessage: 'boom'),
        isNot(const Kyc2FaFailure(errorMessage: 'other')),
      );
    });
  });

  group('$Kyc2FaVerifyState', () {
    test('Failure props pin the errorMessage', () {
      expect(
        const Kyc2FaVerifyFailure(errorMessage: 'boom'),
        const Kyc2FaVerifyFailure(errorMessage: 'boom'),
      );
      expect(
        const Kyc2FaVerifyFailure(errorMessage: 'boom'),
        isNot(const Kyc2FaVerifyFailure(errorMessage: 'other')),
      );
    });
  });
}
