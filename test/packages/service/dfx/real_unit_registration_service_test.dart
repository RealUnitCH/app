import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/config/network_mode.dart';
import 'package:realunit_wallet/packages/repository/cache_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/bitbox_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_email_status.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_user_type.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/dto/real_unit_user_data_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/kyc/kyc_personal_data.dart';
import 'package:realunit_wallet/packages/service/session_cache.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/packages/wallet/wallet_account.dart';

import '../../../helper/fake_bitbox_credentials.dart';

class _MockAppStore extends Mock implements AppStore {}

class _MockWallet extends Mock implements AWallet {}

class _MockAccount extends Mock implements AWalletAccount {}

class _MockCacheRepository extends Mock implements CacheRepository {}

class _MockWalletService extends Mock implements WalletService {}

void main() {
  late _MockAppStore appStore;
  late _MockWallet wallet;
  late _MockAccount account;
  late _MockWalletService walletService;
  late SessionCache session;

  setUp(() {
    appStore = _MockAppStore();
    wallet = _MockWallet();
    account = _MockAccount();
    walletService = _MockWalletService();
    session = SessionCache(_MockCacheRepository());
    session.setAuthToken('jwt-1');

    when(() => appStore.apiConfig).thenReturn(const ApiConfig(networkMode: NetworkMode.mainnet));
    when(() => appStore.sessionCache).thenReturn(session);
    when(() => appStore.wallet).thenReturn(wallet);
    when(() => wallet.primaryAccount).thenReturn(account);
    when(() => walletService.ensureCurrentWalletUnlocked()).thenAnswer((_) async {});
    when(() => walletService.lockCurrentWallet()).thenAnswer((_) async {});
  });

  RealUnitRegistrationService build(http.Client client) {
    when(() => appStore.httpClient).thenReturn(client);
    return RealUnitRegistrationService(appStore, walletService);
  }

  group('$RealUnitRegistrationService.registerEmail', () {
    test('happy path: lowercases the email and returns the parsed status', () async {
      String? sentBody;
      Map<String, String>? sentHeaders;
      final client = MockClient((request) async {
        sentBody = request.body;
        sentHeaders = request.headers;
        return http.Response(jsonEncode({'status': 'email_registered'}), 201);
      });

      final status = await build(client).registerEmail('Alice@Example.COM');

      expect(status, RegistrationEmailStatus.emailRegistered);
      // Email must be lowercased before going on the wire.
      final body = jsonDecode(sentBody!) as Map<String, dynamic>;
      expect(body['email'], 'alice@example.com');
      // Bearer token from session cache.
      expect(sentHeaders!['authorization'], 'Bearer jwt-1');
    });

    test('accepts a 202 Accepted response as success', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({'status': 'merge_requested'}),
          202,
        ),
      );

      final status = await build(client).registerEmail('a@b.com');

      expect(status, RegistrationEmailStatus.mergeRequested);
    });

    test('throws ApiException on a 4xx response', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({'statusCode': 400, 'code': 'BAD_EMAIL', 'message': 'nope'}),
          400,
        ),
      );

      expect(
        () => build(client).registerEmail('a@b.com'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('$RealUnitRegistrationService.completeRegistration', () {
    Registration buildRegistration() => const Registration(
      type: RegistrationUserType.human,
      email: 'a@b.com',
      firstName: 'Ada',
      lastName: 'Lovelace',
      phoneNumber: '+41 79 000 00 00',
      birthday: '1815-12-10',
      nationality: Country(
        id: 41,
        symbol: 'CH',
        name: 'Switzerland',
        kycAllowed: true,
      ),
      addressStreet: 'Bahnhofstrasse',
      addressStreetNumber: '1',
      addressPostalCode: '8000',
      addressCity: 'Zurich',
      addressCountry: Country(
        id: 41,
        symbol: 'CH',
        name: 'Switzerland',
        kycAllowed: true,
      ),
      swissTaxResidence: true,
    );

    test('throws BitboxNotConnectedException when the BitBox is disconnected', () async {
      // Disconnected fake → isConnected = false.
      when(() => account.primaryAddress).thenReturn(
        FakeBitboxCredentials(behavior: FakeBitboxBehavior.disconnect)..bitboxManager = null,
      );
      final client = MockClient((_) async => http.Response('{}', 201));

      expect(
        () => build(client).completeRegistration(buildRegistration()),
        throwsA(isA<BitboxNotConnectedException>()),
      );
    });
  });

  group('$RealUnitRegistrationService.registerWallet', () {
    RealUnitUserDataDto buildUserData() => const RealUnitUserDataDto(
      email: 'a@b.com',
      name: 'Ada Lovelace',
      type: 'HUMAN',
      phoneNumber: '+41 79 000 00 00',
      birthday: '1815-12-10',
      nationality: 'CH',
      addressStreet: 'Bahnhofstrasse 1',
      addressPostalCode: '8000',
      addressCity: 'Zurich',
      addressCountry: 'CH',
      swissTaxResidence: true,
      lang: 'de',
      kycData: KycPersonalData(
        accountType: KycAccountType.personal,
        firstName: 'Ada',
        lastName: 'Lovelace',
        phone: '+41 79 000 00 00',
        address: KycAddress(
          street: 'Bahnhofstrasse',
          zip: '8000',
          city: 'Zurich',
          country: 41,
        ),
      ),
    );

    test('throws BitboxNotConnectedException when the BitBox is disconnected', () async {
      when(() => account.primaryAddress).thenReturn(
        FakeBitboxCredentials(behavior: FakeBitboxBehavior.disconnect)..bitboxManager = null,
      );
      final client = MockClient((_) async => http.Response('{}', 201));

      expect(
        () => build(client).registerWallet(buildUserData()),
        throwsA(isA<BitboxNotConnectedException>()),
      );
    });
  });

  group('malformed JSON responses', () {
    test('registerEmail with non-JSON 201 throws FormatException', () async {
      final client = MockClient((_) async => http.Response('not json', 201));

      expect(
        () => build(client).registerEmail('a@b.com'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
