import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/storage/secure_storage.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

// The SecureStorage keys migrateSecurityFlags moves the flags into. These mirror
// the private constants in SecureStorage; asserting the literal keys pins the
// migration contract — a rename here is a storage-migration event, not a
// refactor, so the test is meant to break if the target key ever changes.
const _biometricEnabledKey = 'biometric.enabled';
const _pinFailedAttemptsKey = 'pin.failedAttempts';
const _pinLockedUntilKey = 'pin.lockedUntil';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockFlutterSecureStorage mockStorage;
  late SecureStorage secureStorage;

  setUp(() {
    mockStorage = _MockFlutterSecureStorage();
    secureStorage = SecureStorage.withStorage(mockStorage);
    when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((_) async {});
  });

  group('migrateSecurityFlags', () {
    test('moves a stored biometric flag into secure storage and clears the pref', () async {
      SharedPreferences.setMockInitialValues({'isBiometricEnabled': true});
      final prefs = await SharedPreferences.getInstance();

      await migrateSecurityFlags(prefs, secureStorage);

      verify(() => mockStorage.write(key: _biometricEnabledKey, value: 'true')).called(1);
      expect(prefs.getBool('isBiometricEnabled'), isNull);
    });

    test('moves the PIN lockout attempt counter and clears the pref', () async {
      SharedPreferences.setMockInitialValues({'pinFailedAttempts': 3});
      final prefs = await SharedPreferences.getInstance();

      await migrateSecurityFlags(prefs, secureStorage);

      verify(() => mockStorage.write(key: _pinFailedAttemptsKey, value: '3')).called(1);
      expect(prefs.getInt('pinFailedAttempts'), isNull);
    });

    test('moves a valid lockout timestamp and clears the pref', () async {
      final until = DateTime.utc(2030, 1, 2, 3, 4, 5);
      SharedPreferences.setMockInitialValues({'pinLockedUntil': until.toIso8601String()});
      final prefs = await SharedPreferences.getInstance();

      await migrateSecurityFlags(prefs, secureStorage);

      verify(() => mockStorage.write(key: _pinLockedUntilKey, value: until.toIso8601String()))
          .called(1);
      expect(prefs.getString('pinLockedUntil'), isNull);
    });

    test('drops an unparseable lockout timestamp without writing it but still clears the pref',
        () async {
      SharedPreferences.setMockInitialValues({'pinLockedUntil': 'not-a-date'});
      final prefs = await SharedPreferences.getInstance();

      await migrateSecurityFlags(prefs, secureStorage);

      verifyNever(() => mockStorage.write(key: _pinLockedUntilKey, value: any(named: 'value')));
      expect(prefs.getString('pinLockedUntil'), isNull);
    });

    test('always clears the legacy isPinEnabled flag', () async {
      SharedPreferences.setMockInitialValues({'isPinEnabled': true});
      final prefs = await SharedPreferences.getInstance();

      await migrateSecurityFlags(prefs, secureStorage);

      expect(prefs.getBool('isPinEnabled'), isNull);
    });

    test('is a no-op on a clean install: nothing migrated, no secure writes', () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      final prefs = await SharedPreferences.getInstance();

      await migrateSecurityFlags(prefs, secureStorage);

      verifyNever(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')));
    });

    test('migrates a zero attempt counter (0 is a stored value, not "absent")', () async {
      // getInt returns 0 for a stored 0; the migration must treat that as a real
      // value to move, not skip it as if the key were missing.
      SharedPreferences.setMockInitialValues({'pinFailedAttempts': 0});
      final prefs = await SharedPreferences.getInstance();

      await migrateSecurityFlags(prefs, secureStorage);

      verify(() => mockStorage.write(key: _pinFailedAttemptsKey, value: '0')).called(1);
      expect(prefs.getInt('pinFailedAttempts'), isNull);
    });

    test('migrates every flag in one pass without interference', () async {
      final until = DateTime.utc(2031, 6, 7, 8, 9, 10);
      SharedPreferences.setMockInitialValues({
        'isBiometricEnabled': false,
        'pinFailedAttempts': 5,
        'pinLockedUntil': until.toIso8601String(),
        'isPinEnabled': true,
      });
      final prefs = await SharedPreferences.getInstance();

      await migrateSecurityFlags(prefs, secureStorage);

      verify(() => mockStorage.write(key: _biometricEnabledKey, value: 'false')).called(1);
      verify(() => mockStorage.write(key: _pinFailedAttemptsKey, value: '5')).called(1);
      verify(() => mockStorage.write(key: _pinLockedUntilKey, value: until.toIso8601String()))
          .called(1);
      expect(prefs.getBool('isBiometricEnabled'), isNull);
      expect(prefs.getInt('pinFailedAttempts'), isNull);
      expect(prefs.getString('pinLockedUntil'), isNull);
      expect(prefs.getBool('isPinEnabled'), isNull);
    });

    test('is idempotent: a second pass migrates nothing (prefs already cleared)', () async {
      SharedPreferences.setMockInitialValues({'pinFailedAttempts': 2});
      final prefs = await SharedPreferences.getInstance();

      await migrateSecurityFlags(prefs, secureStorage);
      await migrateSecurityFlags(prefs, secureStorage);

      // Written exactly once: the second pass sees the cleared pref and is a
      // no-op, matching the idempotency the dartdoc promises.
      verify(() => mockStorage.write(key: _pinFailedAttemptsKey, value: '2')).called(1);
    });
  });
}
