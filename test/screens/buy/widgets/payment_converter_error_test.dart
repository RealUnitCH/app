import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/repository/supported_fiat_repository.dart';
import 'package:realunit_wallet/screens/buy/cubits/buy_converter/buy_converter_cubit.dart';
import 'package:realunit_wallet/screens/buy/widgets/payment_converter.dart';
import 'package:realunit_wallet/styles/currency.dart';

import '../../../helper/helper.dart';

class _MockBuyConverterCubit extends MockCubit<BuyConverterState>
    implements BuyConverterCubit {}

class _MockSupportedFiatRepository extends Mock implements SupportedFiatRepository {}

void main() {
  late _MockSupportedFiatRepository fiatRepo;
  late _MockBuyConverterCubit converterCubit;

  setUp(() {
    fiatRepo = _MockSupportedFiatRepository();
    converterCubit = _MockBuyConverterCubit();
    when(() => converterCubit.state).thenReturn(const BuyConverterState());

    final getIt = GetIt.instance;
    if (getIt.isRegistered<SupportedFiatRepository>()) {
      getIt.unregister<SupportedFiatRepository>();
    }
    getIt.registerSingleton<SupportedFiatRepository>(fiatRepo);
  });

  setUpAll(() => registerFallbackValue(Currency.chf));

  tearDown(() async => GetIt.instance.reset());

  Widget host() => BlocProvider<BuyConverterCubit>.value(
        value: converterCubit,
        child: Scaffold(
          body: PaymentConverter(
            amountController: TextEditingController(),
            resultController: TextEditingController(),
          ),
        ),
      );

  testWidgets(
    'when getBuyable fails the picker is disabled and a SnackBar is shown',
    (tester) async {
      when(() => fiatRepo.getBuyable())
          .thenAnswer((_) async => Future.error(Exception('API down')));

      await tester.pumpApp(host());
      // Drives the failed Future + post-frame SnackBar.
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('buy-currency-picker-disabled')),
        findsOneWidget,
        reason: 'picker must switch to its disabled key on load failure',
      );
      expect(find.byKey(const Key('buy-currency-picker')), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
    },
  );

  testWidgets(
    'on success the picker is enabled (no SnackBar, no disabled key)',
    (tester) async {
      when(() => fiatRepo.getBuyable())
          .thenAnswer((_) async => const [Currency.chf, Currency.eur]);

      await tester.pumpApp(host());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('buy-currency-picker')), findsOneWidget);
      expect(find.byKey(const Key('buy-currency-picker-disabled')), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    },
  );
}
