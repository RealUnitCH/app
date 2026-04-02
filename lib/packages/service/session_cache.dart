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

  Future<void> saveSignature(String address, String signature) async {
    _signature = signature;
    _signatureAddress = address;
    await _cacheRepository.write(_signatureKey, signature);
    await _cacheRepository.write(_signatureAddressKey, address);
  }

  Future<void> loadSignature() async {
    _signature ??= await _cacheRepository.read(_signatureKey);
    _signatureAddress ??= await _cacheRepository.read(_signatureAddressKey);
  }

  Future<void> clear() async {
    _signature = null;
    _signatureAddress = null;
    _authToken = null;
    await _cacheRepository.delete(_signatureKey);
    await _cacheRepository.delete(_signatureAddressKey);
  }
}
