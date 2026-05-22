import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_level.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/dto/user_dto.dart';
import 'package:realunit_wallet/screens/settings_contact/cubit/settings_contact_cubit.dart';

class _MockKycService extends Mock implements DfxKycService {}

UserDto _user({String? mail, bool supportAvailable = false}) => UserDto(
      mail: mail,
      kyc: const UserKycDto(hash: 'h', level: KycLevel.level0, dataComplete: false),
      capabilities: UserCapabilitiesDto(supportAvailable: supportAvailable),
    );

void main() {
  late _MockKycService kyc;

  setUp(() {
    kyc = _MockKycService();
  });

  // The cubit fires init() in its constructor; by the time a stream
  // listener attaches, Loading has already been emitted. We assert the
  // final state and the service call instead of the sequence.
  group('$SettingsContactCubit', () {
    test('reaches Success(supportAvailable: true) when API capability flag is true', () async {
      when(() => kyc.getUser())
          .thenAnswer((_) async => _user(mail: 'a@b.com', supportAvailable: true));

      final cubit = SettingsContactCubit(kyc);
      await cubit.stream.firstWhere((s) => s is SettingsContactSuccess);

      expect((cubit.state as SettingsContactSuccess).supportAvailable, isTrue);
      verify(() => kyc.getUser()).called(1);
    });

    test('reaches Success(supportAvailable: false) when API capability flag is false', () async {
      when(() => kyc.getUser())
          .thenAnswer((_) async => _user(mail: null, supportAvailable: false));

      final cubit = SettingsContactCubit(kyc);
      await cubit.stream.firstWhere((s) => s is SettingsContactSuccess);

      expect((cubit.state as SettingsContactSuccess).supportAvailable, isFalse);
    });

    test('reaches Failure when getUser throws', () async {
      when(() => kyc.getUser()).thenAnswer((_) async => throw Exception('boom'));

      final cubit = SettingsContactCubit(kyc);
      await cubit.stream.firstWhere((s) => s is SettingsContactFailure);

      expect((cubit.state as SettingsContactFailure).message, contains('boom'));
    });

    test('manual init() call after a failure recovers to Success', () async {
      // First call fails (async throw), second call returns a user.
      var calls = 0;
      when(() => kyc.getUser()).thenAnswer((_) async {
        calls++;
        if (calls == 1) throw Exception('transient');
        return _user(mail: 'recovered@b.com', supportAvailable: true);
      });

      final cubit = SettingsContactCubit(kyc);
      // Wait for the constructor-driven init() to settle on Failure.
      await cubit.stream.firstWhere((s) => s is SettingsContactFailure);
      await cubit.init();

      expect(cubit.state, isA<SettingsContactSuccess>());
      expect((cubit.state as SettingsContactSuccess).supportAvailable, isTrue);
    });
  });
}
