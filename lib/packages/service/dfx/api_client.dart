import 'dart:async';

import 'package:http/http.dart';
import 'package:realunit_wallet/generated/release_info.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';

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

  void Function(UpgradeRequiredException error)? onUpgradeRequired;

  RealUnitApiClient([Client? inner]) : _inner = inner ?? Client();

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    request.headers.putIfAbsent('X-Client', () => _clientId);
    request.headers.putIfAbsent('X-Client-Version', () => releaseMarketingVersion);
    final response = await _inner.send(request);
    if (response.statusCode != 426) {
      return response;
    }

    final buffered = await Response.fromStream(response);
    final parsed = ApiException.fromBody(
      buffered.body,
      httpStatusCode: buffered.statusCode,
    );
    final error = parsed is UpgradeRequiredException
        ? parsed
        : UpgradeRequiredException(statusCode: buffered.statusCode);
    onUpgradeRequired?.call(error);

    return StreamedResponse(
      Stream<List<int>>.fromIterable([buffered.bodyBytes]),
      buffered.statusCode,
      contentLength: buffered.contentLength,
      request: buffered.request,
      headers: buffered.headers,
      isRedirect: buffered.isRedirect,
      persistentConnection: buffered.persistentConnection,
      reasonPhrase: buffered.reasonPhrase,
    );
  }

  @override
  void close() => _inner.close();
}
