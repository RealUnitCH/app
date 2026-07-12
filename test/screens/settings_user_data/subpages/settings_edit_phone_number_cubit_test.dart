import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/screens/settings_user_data/subpages/edit_phone_number/cubit/settings_edit_phone_number_cubit.dart';

class _MockKycService extends Mock implements DfxKycService {}

void main() {
  late _MockKycService kyc;

  setUp(() {
    kyc = _MockKycService();
  });

  group('$SettingsEditPhoneNumberCubit', () {
    test('initial state is Initial', () {
      final cubit = SettingsEditPhoneNumberCubit(kycService: kyc);

      expect(cubit.state, isA<SettingsEditPhoneNumberInitial>());
    });

    blocTest<SettingsEditPhoneNumberCubit, SettingsEditPhoneNumberState>(
      'editPhoneNumber emits [Submitting, Success] and forwards the phone',
      build: () {
        when(() => kyc.updateUser(any())).thenAnswer((_) async {});
        return SettingsEditPhoneNumberCubit(kycService: kyc);
      },
      act: (cubit) => cubit.editPhoneNumber('+41790000000'),
      expect: () => [
        const SettingsEditPhoneNumberSubmitting(),
        const SettingsEditPhoneNumberSuccess(),
      ],
      verify: (_) {
        verify(() => kyc.updateUser({'phone': '+41790000000'})).called(1);
      },
    );

    blocTest<SettingsEditPhoneNumberCubit, SettingsEditPhoneNumberState>(
      'editPhoneNumber emits [Submitting, Failure] on service throw',
      build: () {
        when(() => kyc.updateUser(any()))
            .thenAnswer((_) async => throw Exception('boom'));
        return SettingsEditPhoneNumberCubit(kycService: kyc);
      },
      act: (cubit) => cubit.editPhoneNumber('+41790000000'),
      expect: () => [
        const SettingsEditPhoneNumberSubmitting(),
        isA<SettingsEditPhoneNumberFailure>().having(
          (s) => s.message,
          'message',
          contains('boom'),
        ),
      ],
    );
  });
}
