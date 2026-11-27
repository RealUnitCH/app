/// An HTTP request was sent but no response arrived within [timeout]. Thrown
/// only by the per-request limit of `DFXAuthService.authenticatedPost`, never
/// by a sign-in or signature wait before the request, so callers can tell a
/// server that did not answer from a request that never left the device.
class RequestTimeoutException implements Exception {
  final Duration timeout;

  const RequestTimeoutException(this.timeout);

  @override
  String toString() => 'RequestTimeoutException: no response within ${timeout.inSeconds} s';
}
