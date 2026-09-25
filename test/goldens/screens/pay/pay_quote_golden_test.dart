import 'package:bloc_test/bloc_test.dart';
import 'package:clock/clock.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/pay/swap_payment_info.dart';
import 'package:realunit_wallet/screens/pay/cubits/pay_quote/pay_quote_cubit.dart';
import 'package:realunit_wallet/screens/pay/pay_quote_page.dart';

import '../../../helper/helper.dart';

class _MockPayQuoteCubit extends MockCubit<PayQuoteState> implements PayQuoteCubit {}

// Bill 2.00 CHF plus a 0.05 CHF fee. One share pays 1.00 CHF, so the fee is
// 0.05 REALU. Two shares pay 2.00 and do not cover 2.05, so the quote sells
// 3 shares for 3.00 CHF.
final _now = DateTime.utc(2026, 1, 1);
final _expiresAt = DateTime.utc(2026, 1, 1, 0, 5);

const _swap = SwapPaymentInfo(
  id: 99,
  amount: 3,
  estimatedAmount: 3,
  targetAsset: 'ZCHF',
  ethBalance: 1,
  requiredGasEth: 0.001,
  isValid: true,
  ethereumTransactionFeeChf: 0.05,
  ethereumTransactionFeeRealu: 0.05,
);

void main() {
  late _MockPayQuoteCubit quoteCubit;

  setUp(() {
    quoteCubit = _MockPayQuoteCubit();
    when(() => quoteCubit.state).thenReturn(const PayQuoteLoading());
  });

  // PayQuotePage resolves its cubit from getIt and calls load(); the golden
  // renders PayQuoteView directly with a mocked cubit so every state is
  // deterministic without the service/DI graph.
  group('$PayQuoteView', () {
    goldenTest(
      'loading state',
      fileName: 'pay_quote_page_loading',
      constraints: phoneConstraints,
      // The CupertinoActivityIndicator animates forever, so pumpAndSettle
      // would time out; pumpOnce captures the first frame.
      pumpBeforeTest: pumpOnce,
      builder: () => wrapForGolden(
        BlocProvider<PayQuoteCubit>.value(
          value: quoteCubit,
          child: const PayQuoteView(),
        ),
      ),
    );

    // Bill 2.00 CHF. CHF needed on screen is that bill plus the 0.05 fee.
    goldenTest(
      'ready quote with recipient, countdown and REALU total',
      fileName: 'pay_quote_page_ready',
      constraints: phoneConstraints,
      pumpBeforeTest: pumpOnce,
      builder: () {
        when(() => quoteCubit.state).thenReturn(
          PayQuoteReady(
            paymentLinkId: 'pl_realunit_ocp_sepolia',
            quoteId: 'plq_realunit_ocp_sepolia',
            fiatAsset: 'CHF',
            fiatAmount: 2,
            zchfAmount: 2.0,
            merchantName: 'Café Zürich',
            merchantCity: 'Zürich',
            expiresAt: _expiresAt,
            swap: _swap,
          ),
        );
        return withClock(
          Clock.fixed(_now),
          () => wrapForGolden(
            BlocProvider<PayQuoteCubit>.value(
              value: quoteCubit,
              child: const PayQuoteView(),
            ),
          ),
        );
      },
    );

    goldenTest(
      'ready quote with merchant and REALU swap details',
      fileName: 'pay_quote_page_ready_with_merchant',
      constraints: phoneConstraints,
      pumpBeforeTest: pumpOnce,
      builder: () {
        when(() => quoteCubit.state).thenReturn(
          PayQuoteReady(
            paymentLinkId: 'pl_realunit_ocp_sepolia',
            quoteId: 'plq_realunit_ocp_sepolia',
            fiatAsset: 'CHF',
            fiatAmount: 2,
            zchfAmount: 2.0,
            merchantName: 'Café Zürich',
            merchantCity: 'Zürich',
            expiresAt: _expiresAt,
            swap: _swap,
          ),
        );
        return withClock(
          Clock.fixed(_now),
          () => wrapForGolden(
            BlocProvider<PayQuoteCubit>.value(
              value: quoteCubit,
              child: const PayQuoteView(),
            ),
          ),
        );
      },
    );

    goldenTest(
      'expired quote message',
      fileName: 'pay_quote_page_expired',
      constraints: phoneConstraints,
      builder: () {
        when(() => quoteCubit.state).thenReturn(const PayQuoteExpired());
        return wrapForGolden(
          BlocProvider<PayQuoteCubit>.value(
            value: quoteCubit,
            child: const PayQuoteView(),
          ),
        );
      },
    );
  });
}
