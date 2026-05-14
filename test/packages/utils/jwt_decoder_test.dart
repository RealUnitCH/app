import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/utils/jwt_decoder.dart';

String _b64UrlNoPad(Object value) {
  final encoded = base64Url.encode(utf8.encode(json.encode(value)));
  return encoded.replaceAll('=', '');
}

String _jwtFromPayload(Object payload) {
  final header = _b64UrlNoPad({'alg': 'HS256', 'typ': 'JWT'});
  final body = _b64UrlNoPad(payload);
  // Signature is opaque to the decoder; any non-empty placeholder is fine.
  return '$header.$body.sig';
}

void main() {
  group('$JwtDecoder', () {
    test('parses a well-formed JWT payload into a map', () {
      final token = _jwtFromPayload({'sub': 'user-1', 'level': 30});

      final payload = JwtDecoder.parseJwt(token);

      expect(payload['sub'], 'user-1');
      expect(payload['level'], 30);
    });

    test('throws when the token has fewer than three segments', () {
      expect(() => JwtDecoder.parseJwt('only.two'), throwsException);
    });

    test('throws when the token has more than three segments', () {
      expect(() => JwtDecoder.parseJwt('a.b.c.d'), throwsException);
    });

    test('throws when the payload decodes to a non-map (e.g. a list)', () {
      final token = _jwtFromPayload(['not', 'a', 'map']);

      expect(() => JwtDecoder.parseJwt(token), throwsException);
    });

    test('handles base64url padding for length % 4 == 2', () {
      // A two-key payload produces a body that needs '==' padding.
      final token = _jwtFromPayload({'a': 1, 'bb': 2});

      final payload = JwtDecoder.parseJwt(token);

      expect(payload, containsPair('a', 1));
      expect(payload, containsPair('bb', 2));
    });

    test('handles base64url padding for length % 4 == 3', () {
      // A short payload produces a body that needs '=' padding.
      final token = _jwtFromPayload({'a': 1});

      final payload = JwtDecoder.parseJwt(token);

      expect(payload, containsPair('a', 1));
    });

    test('throws on an illegal base64url length (% 4 == 1)', () {
      // Hand-craft a payload segment of length 5 (5 % 4 == 1) to hit the
      // 'Illegal base64url string' branch.
      const illegal = 'header.AAAAA.sig';

      expect(() => JwtDecoder.parseJwt(illegal), throwsException);
    });
  });
}
