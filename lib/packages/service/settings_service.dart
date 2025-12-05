import 'package:realunit_wallet/packages/repository/settings_repository.dart';

class SettingsService {
  final SettingsRepository _repository;

  const SettingsService(SettingsRepository repository) : _repository = repository;

  bool get isTermsAccepted => _repository.termsAccepted;

  void setTermsAccepted(bool value) {
    _repository.termsAccepted = value;
  }
}
