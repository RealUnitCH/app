import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_price_service.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/payment/buy_exceptions.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/payment_info_error.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/eip7702/eip7702_data_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/real_unit_sell_payment_info_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/sell_payment_info.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_sell_payment_info_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/packages/wallet/wallet_account.dart';
import 'package:realunit_wallet/screens/sell/cubits/sell_payment_info/sell_payment_info_cubit.dart';
import 'package:realunit_wallet/styles/currency.dart';

class _MockSellPaymentInfoService extends Mock
    implements RealUnitSellPaymentInfoService {}

class _MockPriceService extends Mock implements DFXPriceService {}

class _MockAppStore extends Mock implements AppStore {}

const _testMnemonic =
    'test test test test test test test test test test test junk';

const _info = SellPaymentInfo(
  id: 1,
  eip7702: Eip7702Data(
    relayerAddress: '0x1',
    delegationManagerAddress: '0x2',
    delegatorAddress: '0x3',
    userNonce: 0,
    domain: Eip7702Domain(
      name: 'RealUnit',
      version: '1',
      chainId: 1,
      verifyingContract: '0x4',
    ),
    types: Eip7702Types(delegation: [], caveat: []),
    message: Eip7702Message(
      delegate: '0x5',
      delegator: '0x6',
      authority: '0x7',
      caveats: [],
      salt: 0,
    ),
    tokenAddress: '0x8',
    amountWei: '0',
    depositAddress: '0x9',
  ),
  amount: 100,
  exchangeRate: 1.0,
  rate: 1.0,
  beneficiary: BeneficiaryDto(iban: 'CH56'),
  estimatedAmount: 100,
  currency: Currency.chf,
  depositAddress: '0xA',
  tokenAddress: '0xB',
  chainId: 1,
  ethBalance: 0.01,
  requiredGasEth: 0.001,
);

void main() {
  late _MockSellPaymentInfoService service;
  late _MockPriceService priceService;
  late _MockAppStore appStore;

  setUpAll(() {
    registerFallbackValue(Currency.chf);
  });

  setUp(() {
    service = _MockSellPaymentInfoService();
    priceService = _MockPriceService();
    appStore = _MockAppStore();
    // Default to a software wallet so isBitbox is false unless overridden.
    when(() => appStore.wallet)
        .thenReturn(SoftwareWallet(1, 'Main', _testMnemonic));
  });

  SellPaymentInfoCubit build() =>
      SellPaymentInfoCubit(service, priceService, appStore);

  group('$SellPaymentInfoCubit', () {
    test('initial state is SellPaymentInfoInitial', () {
      expect(build().state, isA<SellPaymentInfoInitial>());
    });

    group('getPaymentInfo', () {
      test('happy path emits Success with isBitbox=false for a software wallet', () async {
        when(() => service.getPaymentInfo(any(), any(), currency: any(named: 'currency')))
            .thenAnswer((_) async => _info);

        final cubit = build();
        await cubit.getPaymentInfo(amount: '100', iban: 'CH56');

        final success = cubit.state as SellPaymentInfoSuccess;
        expect(success.sellPaymentInfo, _info);
        expect(success.isBitbox, isFalse);
        verify(() => service.getPaymentInfo(100, 'CH56', currency: Currency.chf)).called(1);
      });

      test('Success.isBitbox=true when the current wallet is a BitboxWallet', () async {
        when(() => service.getPaymentInfo(any(), any(), currency: any(named: 'currency')))
            .thenAnswer((_) async => _info);
        when(() => appStore.wallet)
            .thenReturn(_BitboxStubWallet());

        final cubit = build();
        await cubit.getPaymentInfo(amount: '100', iban: 'CH56');

        expect((cubit.state as SellPaymentInfoSuccess).isBitbox, isTrue);
      });

      test('KycLevelRequiredException → Failure(kycRequired, requiredLevel)', () async {
        when(() => service.getPaymentInfo(any(), any(), currency: any(named: 'currency')))
            .thenAnswer(
          (_) async => throw const KycLevelRequiredException(
            statusCode: 403,
            code: 'KYC_REQUIRED',
            message: 'KYC required',
            requiredLevel: 30,
            currentLevel: 10,
          ),
        );

        final cubit = build();
        await cubit.getPaymentInfo(amount: '100', iban: 'CH56');

        final f = cubit.state as SellPaymentInfoFailure;
        expect(f.error, PaymentInfoError.kycRequired);
        expect(f.requiredLevel, 30);
      });

      test('RegistrationRequiredException → Failure(registrationRequired)', () async {
        when(() => service.getPaymentInfo(any(), any(), currency: any(named: 'currency')))
            .thenAnswer(
          (_) async => throw const RegistrationRequiredException(
            statusCode: 403,
            code: 'REGISTRATION_REQUIRED',
            message: 'Sign first',
          ),
        );

        final cubit = build();
        await cubit.getPaymentInfo(amount: '100', iban: 'CH56');

        expect(
          (cubit.state as SellPaymentInfoFailure).error,
          PaymentInfoError.registrationRequired,
        );
      });

      test('generic exception → Failure(unknown) carrying the message', () async {
        when(() => service.getPaymentInfo(any(), any(), currency: any(named: 'currency')))
            .thenAnswer((_) async => throw Exception('network'));

        final cubit = build();
        await cubit.getPaymentInfo(amount: '100', iban: 'CH56');

        final f = cubit.state as SellPaymentInfoFailure;
        expect(f.error, PaymentInfoError.unknown);
        expect(f.message, contains('network'));
      });
    });

    group('validateMinAmount', () {
      test('CHF amount below the 10 CHF floor emits MinAmountNotMet', () async {
        final cubit = build();

        await cubit.validateMinAmount(fiatAmount: '5');

        final s = cubit.state as SellPaymentInfoMinAmountNotMet;
        expect(s.minAmount, 10);
        expect(s.currency, Currency.chf);
      });

      test('CHF amount above the floor leaves state untouched (no MinAmountNotMet)', () async {
        final cubit = build();

        await cubit.validateMinAmount(fiatAmount: '15');

        expect(cubit.state, isA<SellPaymentInfoInitial>());
      });

      test('EUR minimum is scaled by getChfToEurRate (ceil)', () async {
        // 10 CHF × 0.92 EUR/CHF = 9.2 → ceil = 10.
        when(() => priceService.getChfToEurRate()).thenAnswer((_) async => 0.92);

        final cubit = build();
        await cubit.validateMinAmount(fiatAmount: '5', currency: Currency.eur);

        final s = cubit.state as SellPaymentInfoMinAmountNotMet;
        expect(s.minAmount, 10);
        expect(s.currency, Currency.eur);
      });

      test('previously below-min state is cleared back to Initial when amount rises', () async {
        when(() => priceService.getChfToEurRate()).thenAnswer((_) async => 0.92);
        final cubit = build();
        await cubit.validateMinAmount(fiatAmount: '5');
        expect(cubit.state, isA<SellPaymentInfoMinAmountNotMet>());

        await cubit.validateMinAmount(fiatAmount: '20');

        expect(cubit.state, isA<SellPaymentInfoInitial>());
      });

      test('comma separator is normalised to dot', () async {
        final cubit = build();

        await cubit.validateMinAmount(fiatAmount: '15,5');

        // 15.5 ≥ 10 → no MinAmountNotMet.
        expect(cubit.state, isA<SellPaymentInfoInitial>());
      });

      test('empty string is treated as 0 → below minimum', () async {
        final cubit = build();

        await cubit.validateMinAmount(fiatAmount: '');

        expect(cubit.state, isA<SellPaymentInfoMinAmountNotMet>());
      });
    });
  });
}

class _BitboxStubWallet extends AWallet {
  _BitboxStubWallet() : super(1, 'BB');
  @override
  WalletType get walletType => WalletType.bitbox;
  @override
  AWalletAccount get primaryAccount => throw UnimplementedError();
  @override
  AWalletAccount get currentAccount => throw UnimplementedError();
}
