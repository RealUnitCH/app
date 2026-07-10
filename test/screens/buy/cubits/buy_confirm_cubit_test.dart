import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/buy/dto/real_unit_buy_confirm_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_buy_payment_info_service.dart';
import 'package:realunit_wallet/screens/buy/cubits/buy_confirm/buy_confirm_cubit.dart';

class _MockBuyPaymentInfoService extends Mock
    implements RealUnitBuyPaymentInfoService {}

void main() {
  late _MockBuyPaymentInfoService service;

  setUp(() {
    service = _MockBuyPaymentInfoService();
  });

  group('$BuyConfirmCubit', () {
    test('initial state is BuyConfirmInitial', () {
      expect(BuyConfirmCubit(service).state, isA<BuyConfirmInitial>());
    });

    test('confirmPayment emits Success with the confirm remittance info and QR',
        () async {
      when(() => service.confirmPayment(any())).thenAnswer(
        (_) async => const RealUnitBuyConfirmDto(
          reference: 'REF-123',
          remittanceInfo: 'REF-123',
          paymentRequest: 'SPC-payload',
        ),
      );

      final cubit = BuyConfirmCubit(service);
      final done = cubit.stream.firstWhere((s) => s is BuyConfirmSuccess);
      await cubit.confirmPayment(7);
      await done;

      final success = cubit.state as BuyConfirmSuccess;
      expect(success.reference, 'REF-123');
      expect(success.remittanceInfo, 'REF-123');
      expect(success.paymentRequest, 'SPC-payload');
      verify(() => service.confirmPayment(7)).called(1);
    });

    test('confirmPayment is backward compatible: a reference-only DTO emits '
        'Success with the reference and null remittance info / QR', () async {
      when(() => service.confirmPayment(any())).thenAnswer(
        (_) async => const RealUnitBuyConfirmDto(reference: 'REF-456'),
      );

      final cubit = BuyConfirmCubit(service);
      final done = cubit.stream.firstWhere((s) => s is BuyConfirmSuccess);
      await cubit.confirmPayment(9);
      await done;

      final success = cubit.state as BuyConfirmSuccess;
      expect(success.reference, 'REF-456');
      expect(success.remittanceInfo, isNull);
      expect(success.paymentRequest, isNull);
    });

    test('confirmPayment emits Failure(aktionariat) on ApiException 503', () async {
      when(() => service.confirmPayment(any())).thenAnswer(
        (_) async => throw const ApiException(
          statusCode: 503,
          code: 'SERVICE_UNAVAILABLE',
          message: 'Aktionariat down',
        ),
      );

      final cubit = BuyConfirmCubit(service);
      final done = cubit.stream.firstWhere((s) => s is BuyConfirmFailure);
      await cubit.confirmPayment(7);
      await done;

      expect(cubit.state, isA<BuyConfirmFailure>());
      expect((cubit.state as BuyConfirmFailure).error, BuyConfirmError.aktionariat);
    });

    test('confirmPayment emits Failure(unknown) on other ApiException', () async {
      when(() => service.confirmPayment(any())).thenAnswer(
        (_) async => throw const ApiException(
          statusCode: 500,
          code: 'INTERNAL',
          message: 'oops',
        ),
      );

      final cubit = BuyConfirmCubit(service);
      final done = cubit.stream.firstWhere((s) => s is BuyConfirmFailure);
      await cubit.confirmPayment(7);
      await done;

      expect((cubit.state as BuyConfirmFailure).error, BuyConfirmError.unknown);
    });

    test('confirmPayment emits Failure(unknown) on generic exception', () async {
      when(() => service.confirmPayment(any()))
          .thenAnswer((_) async => throw Exception('network'));

      final cubit = BuyConfirmCubit(service);
      final done = cubit.stream.firstWhere((s) => s is BuyConfirmFailure);
      await cubit.confirmPayment(7);
      await done;

      expect((cubit.state as BuyConfirmFailure).error, BuyConfirmError.unknown);
    });
  });
}
