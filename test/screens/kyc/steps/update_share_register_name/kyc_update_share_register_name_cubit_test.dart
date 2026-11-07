import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/bitbox_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/registration_date_unavailable_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/registration_rejected_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/dto/real_unit_registration_response_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/kyc/kyc_personal_data.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_status.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/dto/real_unit_user_data_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';
import 'package:realunit_wallet/packages/wallet/exceptions/signing_cancelled_exception.dart';
import 'package:realunit_wallet/screens/kyc/steps/update_share_register_name/cubits/kyc_update_share_register_name_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/update_share_register_name/cubits/kyc_update_share_register_name_state.dart';

class _MockRegistrationService extends Mock implements RealUnitRegistrationService {}

const _kycData = KycPersonalData(
  accountType: KycAccountType.personal,
  firstName: 'A',
  lastName: 'B',
  phone: '+41',
  address: KycAddress(street: 'S', zip: '8000', city: 'Zurich', country: 41),
);

const _userData = RealUnitUserDataDto(
  email: 'a@b.com',
  name: 'A B',
  type: 'HUMAN',
  phoneNumber: '+41',
  birthday: '2000-01-01',
  nationality: 'CH',
  addressStreet: 'S',
  addressPostalCode: '8000',
  addressCity: 'Zurich',
  addressCountry: 'CH',
  swissTaxResidence: true,
  lang: 'de',
  kycData: _kycData,
);

const _shareRegisterName = 'Ada Lovelace';
const _failed = 'share-register-name-failed';
const _sendFailed = 'share-register-name-send-failed';
const _dateUnavailable = 'registration-date-unavailable';
const _signingCancelled = 'signing-cancelled';

void main() {
  late _MockRegistrationService registrationService;

  setUp(() {
    registrationService = _MockRegistrationService();
  });

  KycUpdateShareRegisterNameCubit build() => KycUpdateShareRegisterNameCubit(
    registrationService,
    _userData,
    _shareRegisterName,
  );

  Future<void> submit(KycUpdateShareRegisterNameCubit cubit) => cubit.submit(
    shareRegisterNameFailed: _failed,
    shareRegisterNameSendFailed: _sendFailed,
    registrationDateUnavailable: _dateUnavailable,
    signingCancelled: _signingCancelled,
  );

  void whenResponse(RealUnitRegistrationResponseDto response) {
    when(
      () => registrationService.updateShareRegisterName(_userData, _shareRegisterName),
    ).thenAnswer((_) async => response);
  }

  group('initial state', () {
    test('starts Ready with the payload the page handed in', () {
      final cubit = build();
      expect(
        cubit.state,
        const KycUpdateShareRegisterNameReady(_userData, _shareRegisterName),
      );
    });
  });

  group('submit', () {
    blocTest<KycUpdateShareRegisterNameCubit, KycUpdateShareRegisterNameState>(
      'completed → Submitting → Success',
      setUp: () {
        whenResponse(
          const RealUnitRegistrationResponseDto(status: RegistrationStatus.completed),
        );
      },
      build: build,
      act: submit,
      expect: () => [
        const KycUpdateShareRegisterNameSubmitting(_userData, _shareRegisterName),
        const KycUpdateShareRegisterNameSuccess(),
      ],
      verify: (_) {
        verify(
          () => registrationService.updateShareRegisterName(_userData, _shareRegisterName),
        ).called(1);
      },
    );

    blocTest<KycUpdateShareRegisterNameCubit, KycUpdateShareRegisterNameState>(
      'retrySubmit triggers the same post as submit',
      setUp: () {
        whenResponse(
          const RealUnitRegistrationResponseDto(status: RegistrationStatus.completed),
        );
      },
      build: build,
      act: (cubit) => cubit.retrySubmit(
        shareRegisterNameFailed: _failed,
        shareRegisterNameSendFailed: _sendFailed,
        registrationDateUnavailable: _dateUnavailable,
        signingCancelled: _signingCancelled,
      ),
      expect: () => [
        const KycUpdateShareRegisterNameSubmitting(_userData, _shareRegisterName),
        const KycUpdateShareRegisterNameSuccess(),
      ],
      verify: (_) {
        verify(
          () => registrationService.updateShareRegisterName(_userData, _shareRegisterName),
        ).called(1);
      },
    );

    blocTest<KycUpdateShareRegisterNameCubit, KycUpdateShareRegisterNameState>(
      'alreadyRegistered → Success',
      setUp: () {
        whenResponse(
          const RealUnitRegistrationResponseDto(status: RegistrationStatus.alreadyRegistered),
        );
      },
      build: build,
      act: submit,
      expect: () => [
        const KycUpdateShareRegisterNameSubmitting(_userData, _shareRegisterName),
        const KycUpdateShareRegisterNameSuccess(),
      ],
    );

    blocTest<KycUpdateShareRegisterNameCubit, KycUpdateShareRegisterNameState>(
      'pendingReview → Success, not the generic failure',
      setUp: () {
        whenResponse(
          const RealUnitRegistrationResponseDto(status: RegistrationStatus.pendingReview),
        );
      },
      build: build,
      act: submit,
      expect: () => [
        const KycUpdateShareRegisterNameSubmitting(_userData, _shareRegisterName),
        const KycUpdateShareRegisterNameSuccess(),
      ],
    );

    blocTest<KycUpdateShareRegisterNameCubit, KycUpdateShareRegisterNameState>(
      'forwardingFailed with a rejection sentence → Failure with that sentence',
      setUp: () {
        whenResponse(
          const RealUnitRegistrationResponseDto(
            status: RegistrationStatus.forwardingFailed,
            rejectionMessage: 'Name abgelehnt',
          ),
        );
      },
      build: build,
      act: submit,
      expect: () => [
        const KycUpdateShareRegisterNameSubmitting(_userData, _shareRegisterName),
        const KycUpdateShareRegisterNameFailure('Name abgelehnt'),
      ],
    );

    blocTest<KycUpdateShareRegisterNameCubit, KycUpdateShareRegisterNameState>(
      'forwardingFailed without a rejection sentence → Failure with the generic copy',
      setUp: () {
        whenResponse(
          const RealUnitRegistrationResponseDto(status: RegistrationStatus.forwardingFailed),
        );
      },
      build: build,
      act: submit,
      expect: () => [
        const KycUpdateShareRegisterNameSubmitting(_userData, _shareRegisterName),
        const KycUpdateShareRegisterNameFailure(_failed),
      ],
    );

    blocTest<KycUpdateShareRegisterNameCubit, KycUpdateShareRegisterNameState>(
      'forwardingFailed returns to idle so submit can run again',
      setUp: () {
        whenResponse(
          const RealUnitRegistrationResponseDto(status: RegistrationStatus.forwardingFailed),
        );
      },
      build: build,
      act: (cubit) async {
        await submit(cubit);
        await submit(cubit);
      },
      expect: () => [
        const KycUpdateShareRegisterNameSubmitting(_userData, _shareRegisterName),
        const KycUpdateShareRegisterNameFailure(_failed),
        const KycUpdateShareRegisterNameSubmitting(_userData, _shareRegisterName),
        const KycUpdateShareRegisterNameFailure(_failed),
      ],
    );

    blocTest<KycUpdateShareRegisterNameCubit, KycUpdateShareRegisterNameState>(
      'RegistrationRejectedException → Failure with its message',
      setUp: () {
        when(
          () => registrationService.updateShareRegisterName(_userData, _shareRegisterName),
        ).thenThrow(
          const RegistrationRejectedException(
            statusCode: 422,
            code: 'REJECTED',
            message: 'Name abgelehnt',
          ),
        );
      },
      build: build,
      act: submit,
      expect: () => [
        const KycUpdateShareRegisterNameSubmitting(_userData, _shareRegisterName),
        const KycUpdateShareRegisterNameFailure('Name abgelehnt'),
      ],
    );

    blocTest<KycUpdateShareRegisterNameCubit, KycUpdateShareRegisterNameState>(
      'RegistrationDateUnavailableException → Failure with the date sentence',
      setUp: () {
        when(
          () => registrationService.updateShareRegisterName(_userData, _shareRegisterName),
        ).thenThrow(
          const RegistrationDateUnavailableException(message: 'missing date'),
        );
      },
      build: build,
      act: submit,
      expect: () => [
        const KycUpdateShareRegisterNameSubmitting(_userData, _shareRegisterName),
        const KycUpdateShareRegisterNameFailure(_dateUnavailable),
      ],
    );

    blocTest<KycUpdateShareRegisterNameCubit, KycUpdateShareRegisterNameState>(
      'SigningCancelledException → Failure with the cancelled sentence',
      setUp: () {
        when(
          () => registrationService.updateShareRegisterName(_userData, _shareRegisterName),
        ).thenThrow(const SigningCancelledException());
      },
      build: build,
      act: submit,
      expect: () => [
        const KycUpdateShareRegisterNameSubmitting(_userData, _shareRegisterName),
        const KycUpdateShareRegisterNameFailure(_signingCancelled),
      ],
    );

    blocTest<KycUpdateShareRegisterNameCubit, KycUpdateShareRegisterNameState>(
      'BitboxNotConnectedException → BitboxRequired, not a failure',
      setUp: () {
        when(
          () => registrationService.updateShareRegisterName(_userData, _shareRegisterName),
        ).thenThrow(const BitboxNotConnectedException());
      },
      build: build,
      act: submit,
      expect: () => [
        const KycUpdateShareRegisterNameSubmitting(_userData, _shareRegisterName),
        const KycUpdateShareRegisterNameBitboxRequired(_userData, _shareRegisterName),
      ],
    );

    blocTest<KycUpdateShareRegisterNameCubit, KycUpdateShareRegisterNameState>(
      'any other error → Failure with the send sentence, not the register rejection',
      setUp: () {
        when(
          () => registrationService.updateShareRegisterName(_userData, _shareRegisterName),
        ).thenThrow(Exception('network down'));
      },
      build: build,
      act: submit,
      expect: () => [
        const KycUpdateShareRegisterNameSubmitting(_userData, _shareRegisterName),
        const KycUpdateShareRegisterNameFailure(_sendFailed),
      ],
    );
  });
}
