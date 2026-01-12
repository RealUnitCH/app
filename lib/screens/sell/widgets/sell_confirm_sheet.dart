import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/sell_payment_info.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_sell_payment_info_service.dart';
import 'package:realunit_wallet/screens/sell/cubits/sell_confirm/sell_confirm_cubit.dart';

class SellConfirmSheet extends StatelessWidget {
  final SellPaymentInfo paymentInfo;

  const SellConfirmSheet({super.key, required this.paymentInfo});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SellConfirmCubit(
        getIt<RealUnitSellPaymentInfoService>(),
      ),
      child: SellConfirmSheetView(
        paymentInfo: paymentInfo,
      ),
    );
  }
}

class SellConfirmSheetView extends StatelessWidget {
  final SellPaymentInfo paymentInfo;

  const SellConfirmSheetView({super.key, required this.paymentInfo});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 6.0,
                vertical: 4.0,
              ),
              child: AppBar(
                title: const Text(
                  'Verkauf bestätigen',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                spacing: 8.0,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Amount:'),
                      Text('${paymentInfo.amount}'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Exchange Rate:'),
                      const Spacer(),
                      Text('${paymentInfo.exchangeRate}'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Estimated Amount:'),
                      const Spacer(),
                      Text('${paymentInfo.estimatedAmount}'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Currency:'),
                      const Spacer(),
                      Text('${paymentInfo.currency}'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Beneficiary:'),
                      const Spacer(),
                      Text(paymentInfo.beneficiary.iban),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: FilledButton(
                onPressed: null,
                //onPressed: () => context.read<SellConfirmCubit>().confirmPayment(paymentInfo),
                child: Text(
                  S.of(context).confirm,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
