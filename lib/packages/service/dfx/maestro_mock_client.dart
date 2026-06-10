import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart';

/// Intercepts HTTP calls when the app is compiled with
/// `--dart-define=MAESTRO_MOCK=true` and returns canned JSON responses for
/// all DFX API endpoints the KYC / link-wallet flow needs.
///
/// Unknown paths receive a default empty 200 to prevent crashes on
/// dashboard / price / balance calls. The mock is only compiled into the
/// binary when [inMaestroMockMode] is true — production builds are
/// unaffected.
class MaestroMockClient extends BaseClient {
  static const _mockToken = 'maestro-mock-token';
  static const _mockKycHash = 'maestro-kyc-hash';

  /// Whether the current build was compiled with `MAESTRO_MOCK=true`.
  static bool get inMaestroMockMode =>
      const bool.fromEnvironment('MAESTRO_MOCK', defaultValue: false);

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    final path = request.url.path;
    final method = request.method;

    final resp = _response(method, path);
    if (resp != null) return resp;

    // Unknown path — return a valid empty JSON response so the app
    // doesn't crash on dashboard / price / balance API calls.
    return _json(200, <String, dynamic>{});
  }

  StreamedResponse? _response(String method, String path) {
    switch (path) {
      case '/v1/auth':
        if (method == 'POST') {
          return _json(201, {'accessToken': _mockToken});
        }
        break;
      case '/v2/user':
        if (method == 'GET') {
          return _json(200, _user());
        }
        if (method == 'PUT') {
          return _json(200, _user());
        }
        break;
      case '/v2/kyc':
        if (method == 'GET') {
          return _json(200, _kycStatus());
        }
        if (method == 'PUT') {
          return _json(200, _continueKycResponse());
        }
        break;
      case '/v1/realunit/registration':
        if (method == 'GET') {
          return _json(200, {
            'state': 'AddWallet',
            'userData': _userData(),
          });
        }
        break;
      case '/v1/realunit/register/wallet':
        if (method == 'POST') {
          return _json(201, {'status': 'completed'});
        }
        break;
      case '/v1/realunit/register/email':
        if (method == 'POST') {
          return _json(201, {'status': 'completed'});
        }
        break;
    }
    return null;
  }

  Map<String, dynamic> _user() => {
    'mail': 'shareholder@example.com',
    'kyc': {
      'hash': _mockKycHash,
      'level': 10,
      'dataComplete': true,
    },
    'capabilities': <String, dynamic>{},
  };

  Map<String, dynamic> _kycStatus() => {
    'kycLevel': 10,
    'kycSteps': _kycSteps(),
    'processStatus': 'InProgress',
  };

  Map<String, dynamic> _continueKycResponse() => {
    'currentStep': {
      'name': 'ContactData',
      'session': {'url': 'https://localhost:3000/v2/kyc/session/1'},
    },
  };

  List<Map<String, dynamic>> _kycSteps() => [
    {
      'name': 'ContactData',
      'status': 'Completed',
      'sequenceNumber': 0,
      'isCurrent': false,
      'isRequired': true,
    },
    {
      'name': 'RealUnitRegistration',
      'status': 'Completed',
      'sequenceNumber': 1,
      'isCurrent': false,
      'isRequired': true,
    },
  ];

  Map<String, dynamic> _userData() => {
    'email': 'shareholder@example.com',
    'name': 'Max Mustermann',
    'type': 'Personal',
    'phoneNumber': '+41791234567',
    'birthday': '1990-01-01',
    'nationality': 'CH',
    'addressStreet': 'Bahnhofstrasse 1',
    'addressPostalCode': '8001',
    'addressCity': 'Zürich',
    'addressCountry': 'CH',
    'swissTaxResidence': true,
    'lang': 'DE',
    'kycData': {
      'accountType': 'Personal',
      'firstName': 'Max',
      'lastName': 'Mustermann',
      'phone': '+41791234567',
      'address': {
        'street': 'Bahnhofstrasse',
        'houseNumber': '1',
        'zip': '8001',
        'city': 'Zürich',
        'country': 1,
      },
    },
  };

  StreamedResponse _json(int code, Object body) {
    final bytes = utf8.encode(jsonEncode(body));
    return StreamedResponse(
      Stream.value(bytes),
      code,
      contentLength: bytes.length,
      headers: {'content-type': 'application/json'},
    );
  }
}
