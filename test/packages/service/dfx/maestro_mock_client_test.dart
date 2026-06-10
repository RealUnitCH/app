import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:realunit_wallet/packages/service/dfx/maestro_mock_client.dart';

void main() {
  group('MaestroMockClient', () {
    late MaestroMockClient client;

    setUp(() {
      client = MaestroMockClient();
    });

    Future<Map<String, dynamic>> getJson(String path) async {
      final request = Request('GET', Uri.parse('https://api.dfx.swiss$path'));
      final response = await client.send(request);
      final body = await response.stream.bytesToString();
      return jsonDecode(body) as Map<String, dynamic>;
    }

    Future<Map<String, dynamic>> putJson(String path) async {
      final request = Request('PUT', Uri.parse('https://api.dfx.swiss$path'));
      final response = await client.send(request);
      final body = await response.stream.bytesToString();
      return jsonDecode(body) as Map<String, dynamic>;
    }

    group('GET /v2/user', () {
      test('returns user with email and kyc hash', () async {
        final json = await getJson('/v2/user');
        expect(json['mail'], 'shareholder@example.com');
        expect((json['kyc'] as Map<String, dynamic>)['hash'], 'maestro-kyc-hash');
        expect((json['kyc'] as Map<String, dynamic>)['level'], 10);
      });
    });

    group('PUT /v2/user', () {
      test('returns same user shape', () async {
        final json = await putJson('/v2/user');
        expect(json['mail'], isNotNull);
      });
    });

    group('GET /v2/kyc', () {
      test('returns kyc status with InProgress processStatus', () async {
        final json = await getJson('/v2/kyc');
        expect(json['kycLevel'], 10);
        expect(json['processStatus'], 'InProgress');
        final steps = json['kycSteps'] as List<dynamic>;
        expect(steps.length, 2);
      });
    });

    group('PUT /v2/kyc', () {
      test('returns session response with required fields', () async {
        final json = await putJson('/v2/kyc');
        expect(json['kycLevel'], 10);
        expect(json['processStatus'], 'InProgress');
        expect(json['kycSteps'], isNotEmpty);
        final currentStep = json['currentStep'] as Map<String, dynamic>;
        expect(currentStep['name'], 'ContactData');
        expect(currentStep['status'], 'Completed');
        expect(currentStep['sequenceNumber'], 0);
        expect(currentStep['isCurrent'], true);
        final session = currentStep['session'] as Map<String, dynamic>;
        expect(session['url'], isNotEmpty);
        expect(session['type'], 'API');
      });
    });

    group('GET /v1/realunit/registration', () {
      test('returns AddWallet state with userData', () async {
        final json = await getJson('/v1/realunit/registration');
        expect(json['state'], 'AddWallet');
        final userData = json['userData'] as Map<String, dynamic>;
        expect(userData['email'], 'shareholder@example.com');
        expect(userData['name'], 'Max Mustermann');
        expect(userData['swissTaxResidence'], true);
        final kycData = userData['kycData'] as Map<String, dynamic>;
        expect(kycData['accountType'], 'Personal');
      });
    });

    group('POST /v1/realunit/register/wallet', () {
      test('returns 201 with completed status', () async {
        final request = Request(
          'POST',
          Uri.parse('https://api.dfx.swiss/v1/realunit/register/wallet'),
        );
        final response = await client.send(request);
        expect(response.statusCode, 201);
        final body = await response.stream.bytesToString();
        final json = jsonDecode(body) as Map<String, dynamic>;
        expect(json['status'], 'completed');
      });
    });

    group('POST /v1/realunit/register/email', () {
      test('returns 201 with completed status', () async {
        final request = Request(
          'POST',
          Uri.parse('https://api.dfx.swiss/v1/realunit/register/email'),
        );
        final response = await client.send(request);
        expect(response.statusCode, 201);
        final body = await response.stream.bytesToString();
        final json = jsonDecode(body) as Map<String, dynamic>;
        expect(json['status'], 'completed');
      });
    });

    group('unknown paths pass through to inner client', () {
      test('forwards request to inner client (real API)', () async {
        // Use a MockClient as inner to verify pass-through behavior.
        final mockInner = MockClient((request) async {
          expect(request.url.path, '/v1/some/real/endpoint');
          return Response('{"real": "data"}', 200);
        });
        final passThroughClient = MaestroMockClient(mockInner);

        final request = Request(
          'GET',
          Uri.parse('https://api.dfx.swiss/v1/some/real/endpoint'),
        );
        final response = await passThroughClient.send(request);
        final body = await response.stream.bytesToString();
        final json = jsonDecode(body) as Map<String, dynamic>;
        expect(json['real'], 'data');
      });
    });

    group('inMaestroMockMode', () {
      test('is false by default (no compile-time flag in test environment)', () {
        expect(MaestroMockClient.inMaestroMockMode, isFalse);
      });
    });

    group('close', () {
      test('delegates to inner client', () {
        expect(() => client.close(), returnsNormally);
      });
    });
  });
}
