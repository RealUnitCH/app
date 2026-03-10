import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/payment_info_error.dart';
import 'package:realunit_wallet/screens/buy/cubits/buy_payment_info/buy_payment_info_cubit.dart';
import 'package:realunit_wallet/screens/kyc/kyc_page_manager.dart';
import 'package:realunit_wallet/styles/colors.dart';

class PaymentAdditionalActionNeededButton extends StatelessWidget {
  final TextEditingController amountController;

  const PaymentAdditionalActionNeededButton({
    super.key,
    required this.amountController,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BuyPaymentInfoCubit, BuyPaymentInfoState>(
      builder: (context, paymentState) {
        if (paymentState is BuyPaymentInfoFailure) {
          if (paymentState.error == PaymentInfoError.minAmountNotMet) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Column(
                spacing: 8.0,
                children: [
                  Text(
                    S.of(context).buyMinAmount,
                    style: const TextStyle(
                      color: RealUnitColors.neutral500,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: null,
                      child: Text(S.of(context).next),
                    ),
                  ),
                ],
              ),
            );
          }
          if (paymentState.error == PaymentInfoError.registrationRequired) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    await context.push(KycPageManager.routeName);
                    if (context.mounted) {
                      context.read<BuyPaymentInfoCubit>().getPaymentInfo(
                        amount: amountController.text,
                      );
                    }
                  },
                  child: Text(S.of(context).next),
                ),
              ),
            );
          }
          if (paymentState.error == PaymentInfoError.kycRequired) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    await context.push(
                      KycPageManager.routeName,
                      extra: paymentState.requiredLevel,
                    );
                    if (context.mounted) {
                      context.read<BuyPaymentInfoCubit>().getPaymentInfo(
                        amount: amountController.text,
                      );
                    }
                  },
                  child: Text(S.of(context).next),
                ),
              ),
            );
          }
        }
        return const SizedBox.shrink();
      },
    );
  }
}
