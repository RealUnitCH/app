import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_level.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/dto/user_dto.dart';
import 'package:realunit_wallet/screens/settings_contact/cubit/settings_contact_cubit.dart';

class _MockKycService extends Mock implements DfxKycService {}

UserDto _user({
  String? mail,
  CreateSupportTicketCapabilityDto? createSupportTicket,
  bool includeCapabilities = true,
}) {
  return UserDto(
    mail: mail,
    kyc: const UserKycDto(
      hash: 'h',
      level: KycLevel.level10,
      dataComplete: true,
    ),
    capabilities: includeCapabilities
        ? UserCapabilitiesDto(createSupportTicket: createSupportTicket)
        : const UserCapabilitiesDto(),
  );
}

void main() {
  late _MockKycService kycService;

  setUp(() {
    kycService = _MockKycService();
  });

  SettingsContactCubit build() => SettingsContactCubit(kycService);

  group('initial state', () {
    test('emits $SettingsContactInitial', () {
      expect(build().state, isA<SettingsContactInitial>());
    });
  });

  group('init', () {
    blocTest<SettingsContactCubit, SettingsContactState>(
      'user with mail set + capability.available=true → Loading → Success(capability available)',
      setUp: () => when(() => kycService.getUser()).thenAnswer(
        (_) async => _user(
          mail: 'a@b.com',
          createSupportTicket: const CreateSupportTicketCapabilityDto(available: true),
        ),
      ),
      build: build,
      act: (c) => c.init(),
      expect: () => [
        const SettingsContactLoading(),
        isA<SettingsContactSuccess>()
            .having((s) => s.capability, 'capability', isNotNull)
            .having((s) => s.capability!.available, 'available', isTrue)
            .having(
              (s) => s.capability!.missingPrerequisite,
              'missingPrerequisite',
              isNull,
            ),
      ],
    );

    blocTest<SettingsContactCubit, SettingsContactState>(
      'user without mail + capability.available=false + Email prerequisite → Success(prerequisite)',
      setUp: () => when(() => kycService.getUser()).thenAnswer(
        (_) async => _user(
          createSupportTicket: const CreateSupportTicketCapabilityDto(
            available: false,
            missingPrerequisite: MissingPrerequisite.email,
          ),
        ),
      ),
      build: build,
      act: (c) => c.init(),
      expect: () => [
        const SettingsContactLoading(),
        isA<SettingsContactSuccess>()
            .having((s) => s.capability!.available, 'available', isFalse)
            .having(
              (s) => s.capability!.missingPrerequisite,
              'missingPrerequisite',
              MissingPrerequisite.email,
            ),
      ],
    );

    blocTest<SettingsContactCubit, SettingsContactState>(
      'legacy backend (capability null) → Success(capability: null), graceful fallback',
      setUp: () => when(() => kycService.getUser()).thenAnswer(
        (_) async => _user(mail: 'a@b.com'),
      ),
      build: build,
      act: (c) => c.init(),
      expect: () => [
        const SettingsContactLoading(),
        isA<SettingsContactSuccess>().having(
          (s) => s.capability,
          'capability',
          isNull,
        ),
      ],
    );

    blocTest<SettingsContactCubit, SettingsContactState>(
      '$ApiException → Loading → Failure(message)',
      setUp: () => when(() => kycService.getUser()).thenAnswer(
        (_) async => throw const ApiException(
          code: 'WHATEVER',
          message: 'boom',
        ),
      ),
      build: build,
      act: (c) => c.init(),
      expect: () => [
        const SettingsContactLoading(),
        const SettingsContactFailure(message: 'boom'),
      ],
    );

    blocTest<SettingsContactCubit, SettingsContactState>(
      'generic exception → Failure(toString)',
      setUp: () => when(() => kycService.getUser()).thenAnswer(
        (_) async => throw Exception('socket'),
      ),
      build: build,
      act: (c) => c.init(),
      expect: () => [
        const SettingsContactLoading(),
        isA<SettingsContactFailure>().having(
          (s) => s.message,
          'message',
          contains('socket'),
        ),
      ],
    );
  });
}
