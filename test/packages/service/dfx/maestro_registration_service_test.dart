import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/bitbox_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/maestro_registration_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/kyc/kyc_personal_data.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/dto/real_unit_user_data_dto.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';

class MockAppStore extends Mock implements AppStore {}
class MockWalletService extends Mock implements WalletService {}

void main() {
  group('MaestroRegistrationService', () {
    final userData = RealUnitUserDataDto(
      email: 'test@example.com',
      name: 'Max Mustermann',
      type: 'Personal',
      phoneNumber: '+41791234567',
      birthday: '1990-01-01',
      nationality: 'CH',
      addressStreet: 'Bahnhofstrasse 1',
      addressPostalCode: '8001',
      addressCity: 'Zürich',
      addressCountry: 'CH',
      swissTaxResidence: true,
      lang: 'DE',
      kycData: KycPersonalData(
        accountType: KycAccountType.personal,
        firstName: 'Max',
        lastName: 'Mustermann',
        phone: '+41791234567',
        address: KycAddress(
          street: 'Bahnhofstrasse',
          houseNumber: '1',
          zip: '8001',
          city: 'Zürich',
          country: 1,
        ),
      ),
    );

    test('first registerWallet() throws BitboxNotConnectedException, retry delegates',
        () async {
      final appStore = MockAppStore();
      final walletService = MockWalletService();

      // Stub just enough for the super.registerWallet() chain to fail with
      // a non-BitBox exception. We don't need a full wallet set up —
      // any exception that isn't BitboxNotConnectedException proves the
      // retry path delegates to super instead of re-throwing our synthetic.
      when(() => walletService.ensureCurrentWalletUnlocked())
          .thenAnswer((_) async {});

      // appStore.wallet will throw because we haven't set it — that's fine.
      // The expectation is isNot<BitboxNotConnectedException>.

      final service = MaestroRegistrationService(appStore, walletService);

      // First call — synthetic BitBox disconnect.
      await expectLater(
        service.registerWallet(userData),
        throwsA(isA<BitboxNotConnectedException>()),
      );

      // Second call delegates to super. The super chain fails because
      // appStore.wallet throws, but crucially it does NOT throw
      // BitboxNotConnectedException (our synthetic flag has been cleared).
      await expectLater(
        service.registerWallet(userData),
        throwsA(isNot(isA<BitboxNotConnectedException>())),
      );
    });
  });
}
