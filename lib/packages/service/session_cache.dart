import 'package:realunit_wallet/packages/repository/cache_repository.dart';

class SessionCache {
  static const _signatureKey = 'cached_signature';
  static const _signatureAddressKey = 'cached_signature_address';

  final CacheRepository _cacheRepository;

  SessionCache(CacheRepository cacheRepository) : _cacheRepository = cacheRepository;

  String? _authToken;
  String? _signature;
  String? _signatureAddress;

  String? get authToken => _authToken;
  String? get signature => _signature;
  String? get signatureAddress => _signatureAddress;

  void setAuthToken(String token) => _authToken = token;

  void clearAuthToken() => _authToken = null;

  void saveSignature(String address, String signature) {
    _signature = signature;
    _signatureAddress = address;
  }

  void loadSignature() {
    // No-op: signatures are no longer persisted to disk.
    // They are regenerated on each app start via fresh signing.
  }

  Future<void> clear() async {
    _signature = null;
    _signatureAddress = null;
    _authToken = null;
    // Clean up any previously persisted signatures
    await _cacheRepository.delete(_signatureKey);
    await _cacheRepository.delete(_signatureAddressKey);
  }
}
