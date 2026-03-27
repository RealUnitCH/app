import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_price_service.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/payment/buy_exceptions.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/buy/buy_payment_info.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/payment_info_error.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/kyc/kyc_personal_data.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_status.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/dto/real_unit_user_data_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/wallet/real_unit_wallet_status_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_buy_payment_info_service.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_wallet_service.dart';
import 'package:realunit_wallet/screens/buy/cubits/buy_payment_info/buy_payment_info_cubit.dart';
import 'package:realunit_wallet/styles/currency.dart';

class MockRealUnitBuyPaymentInfoService extends Mock implements RealUnitBuyPaymentInfoService {}

class MockDfxPriceService extends Mock implements DFXPriceService {}

class MockRealUnitWalletService extends Mock implements RealUnitWalletService {}

class MockRealUnitRegistrationService extends Mock implements RealUnitRegistrationService {}

void main() {
  late MockRealUnitBuyPaymentInfoService mockBuyPaymentInfoService;
  late MockDfxPriceService mockPriceService;
  late MockRealUnitWalletService mockWalletService;
  late MockRealUnitRegistrationService mockRegistrationService;

  const testAmount = '300';
  const testCurrency = Currency.chf;

  final testUserData = RealUnitUserDataDto(
    email: 'test@example.com',
    name: 'Test User',
    type: 'Personal',
    phoneNumber: '+41791234567',
    birthday: '1990-01-01',
    nationality: 'CH',
    addressStreet: 'Test Street 1',
    addressPostalCode: '8000',
    addressCity: 'Zurich',
    addressCountry: 'CH',
    swissTaxResidence: true,
    lang: 'DE',
    kycData: const KycPersonalData(
      accountType: KycAccountType.personal,
      firstName: 'Test',
      lastName: 'User',
      phone: '+41791234567',
      address: KycAddress(
        street: 'Test Street',
        houseNumber: '1',
        zip: '8000',
        city: 'Zurich',
        country: 756, // Switzerland country ID
      ),
    ),
  );

  const testPaymentInfo = BuyPaymentInfo(
    id: 1,
    iban: 'CH1234567890',
    bic: 'TESTBIC',
    name: 'Test Bank',
    street: 'Bank Street',
    number: '1',
    zip: '8000',
    city: 'Zurich',
    country: 'CH',
    currency: Currency.chf,
  );

  setUp(() {
    mockBuyPaymentInfoService = MockRealUnitBuyPaymentInfoService();
    mockPriceService = MockDfxPriceService();
    mockWalletService = MockRealUnitWalletService();
    mockRegistrationService = MockRealUnitRegistrationService();
  });

  setUpAll(() {
    registerFallbackValue(testUserData);
    registerFallbackValue(Currency.chf);
  });

  BuyPaymentInfoCubit createCubit() => BuyPaymentInfoCubit(
        mockBuyPaymentInfoService,
        mockPriceService,
        mockWalletService,
        mockRegistrationService,
      );

  group('BuyPaymentInfoCubit', () {
    group('auto wallet registration', () {
      blocTest<BuyPaymentInfoCubit, BuyPaymentInfoState>(
        'auto-registers wallet when user data exists and returns success',
        setUp: () {
          var callCount = 0;
          when(() => mockBuyPaymentInfoService.getPaymentInfo(any(), currency: any(named: 'currency')))
              .thenAnswer((_) async {
            callCount++;
            if (callCount == 1) {
              throw const RegistrationRequiredException(code: 'REGISTRATION_REQUIRED', message: 'Registration required');
            }
            return testPaymentInfo;
          });
          when(() => mockWalletService.getWalletStatus())
              .thenAnswer((_) async => RealUnitWalletStatusDto(isRegistered: false, realUnitUserDataDto: testUserData));
          when(() => mockRegistrationService.registerWallet(any()))
              .thenAnswer((_) async => RegistrationStatus.completed);
        },
        build: createCubit,
        act: (cubit) => cubit.getPaymentInfo(amount: testAmount, currency: testCurrency),
        expect: () => [
          const BuyPaymentInfoLoading(),
          const BuyPaymentInfoSuccess(testPaymentInfo),
        ],
        verify: (_) {
          verify(() => mockWalletService.getWalletStatus()).called(1);
          verify(() => mockRegistrationService.registerWallet(testUserData)).called(1);
        },
      );

      blocTest<BuyPaymentInfoCubit, BuyPaymentInfoState>(
        'returns registration required error when user data is null',
        setUp: () {
          when(() => mockBuyPaymentInfoService.getPaymentInfo(any(), currency: any(named: 'currency')))
              .thenThrow(const RegistrationRequiredException(code: 'REGISTRATION_REQUIRED', message: 'Registration required'));
          when(() => mockWalletService.getWalletStatus())
              .thenAnswer((_) async => RealUnitWalletStatusDto(isRegistered: false, realUnitUserDataDto: null));
        },
        build: createCubit,
        act: (cubit) => cubit.getPaymentInfo(amount: testAmount, currency: testCurrency),
        expect: () => [
          const BuyPaymentInfoLoading(),
          const BuyPaymentInfoFailure(PaymentInfoError.registrationRequired),
        ],
        verify: (_) {
          verify(() => mockWalletService.getWalletStatus()).called(1);
          verifyNever(() => mockRegistrationService.registerWallet(any()));
        },
      );

      blocTest<BuyPaymentInfoCubit, BuyPaymentInfoState>(
        'returns registration required error when wallet registration fails',
        setUp: () {
          when(() => mockBuyPaymentInfoService.getPaymentInfo(any(), currency: any(named: 'currency')))
              .thenThrow(const RegistrationRequiredException(code: 'REGISTRATION_REQUIRED', message: 'Registration required'));
          when(() => mockWalletService.getWalletStatus())
              .thenAnswer((_) async => RealUnitWalletStatusDto(isRegistered: false, realUnitUserDataDto: testUserData));
          when(() => mockRegistrationService.registerWallet(any()))
              .thenThrow(Exception('Registration failed'));
        },
        build: createCubit,
        act: (cubit) => cubit.getPaymentInfo(amount: testAmount, currency: testCurrency),
        expect: () => [
          const BuyPaymentInfoLoading(),
          const BuyPaymentInfoFailure(PaymentInfoError.registrationRequired),
        ],
        verify: (_) {
          verify(() => mockWalletService.getWalletStatus()).called(1);
          verify(() => mockRegistrationService.registerWallet(testUserData)).called(1);
        },
      );
    });
  });
}
