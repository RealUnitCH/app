import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/repository/settings_repository.dart';
import 'package:realunit_wallet/packages/service/settings_service.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late _MockSettingsRepository repo;
  late SettingsService service;

  setUp(() {
    repo = _MockSettingsRepository();
    service = SettingsService(repo);
  });

  group('$SettingsService', () {
    group('terms accepted', () {
      test('reads through to the repository', () {
        when(() => repo.termsAccepted).thenReturn(true);

        expect(service.isTermsAccepted, isTrue);
      });

      test('returns false when the repository reports false', () {
        when(() => repo.termsAccepted).thenReturn(false);

        expect(service.isTermsAccepted, isFalse);
      });

      test('writes through to the repository', () {
        service.setTermsAccepted(true);

        verify(() => repo.termsAccepted = true).called(1);
      });

      test('propagates the false value as well', () {
        service.setTermsAccepted(false);

        verify(() => repo.termsAccepted = false).called(1);
      });
    });

    group('software terms accepted', () {
      test('reads through to the repository', () {
        when(() => repo.softwareTermsAccepted).thenReturn(true);

        expect(service.isSoftwareTermsAccepted, isTrue);
      });

      test('writes through to the repository', () {
        service.setSoftwareTermsAccepted(true);

        verify(() => repo.softwareTermsAccepted = true).called(1);
      });

      test('software-terms and terms are independent settings', () {
        when(() => repo.termsAccepted).thenReturn(true);
        when(() => repo.softwareTermsAccepted).thenReturn(false);

        expect(service.isTermsAccepted, isTrue);
        expect(service.isSoftwareTermsAccepted, isFalse);
      });
    });
  });
}
