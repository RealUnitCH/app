import 'package:http/http.dart';
import 'package:realunit_wallet/generated/release_info.dart';

/// HTTP client wrapper that tags every outgoing request with an `X-Client`
/// header, so the DFX API can attribute and trace realunit-app traffic.
///
/// Wraps the single shared [Client] in [AppStore.httpClient]; every service
/// — directly or via [DFXAuthService] — routes through it, so the header is
/// added to all calls without touching individual call sites.
///
/// [putIfAbsent] leaves any header a caller already set untouched.
class RealUnitApiClient extends BaseClient {
  static const _clientId = 'realunit-app';

  final Client _inner;

  RealUnitApiClient([Client? inner]) : _inner = inner ?? Client();

  @override
  Future<StreamedResponse> send(BaseRequest request) {
    request.headers.putIfAbsent('X-Client', () => _clientId);
    request.headers.putIfAbsent('X-Client-Version', () => releaseMarketingVersion);
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}
