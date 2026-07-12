import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/repository/supported_language_repository.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_language_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/language/dto/dfx_language_dto.dart';
import 'package:realunit_wallet/styles/language.dart';

class _MockLanguageService extends Mock implements DfxLanguageService {}

void main() {
  late _MockLanguageService languageService;
  late SupportedLanguageRepository repo;

  setUp(() {
    languageService = _MockLanguageService();
    repo = SupportedLanguageRepository(languageService);
  });

  group('$SupportedLanguageRepository', () {
    test('getEnabled returns only enabled, locally-supported languages', () async {
      when(() => languageService.getAllLanguages()).thenAnswer((_) async => const [
        DfxLanguageDto(id: 1, symbol: 'EN', name: 'English', foreignName: 'English', enable: true),
        DfxLanguageDto(id: 2, symbol: 'DE', name: 'German', foreignName: 'Deutsch', enable: true),
        DfxLanguageDto(id: 3, symbol: 'FR', name: 'French', foreignName: 'Français', enable: false),
      ]);

      final enabled = await repo.getEnabled();

      expect(enabled, [Language.en, Language.de]);
    });

    test('unknown backend languages are skipped', () async {
      when(() => languageService.getAllLanguages()).thenAnswer((_) async => const [
        DfxLanguageDto(id: 1, symbol: 'EN', name: 'English', foreignName: 'English', enable: true),
        DfxLanguageDto(id: 99, symbol: 'ES', name: 'Spanish', foreignName: 'Español', enable: true),
      ]);

      final enabled = await repo.getEnabled();

      expect(enabled, [Language.en]);
    });
  });
}
