import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/payment_info_error.dart';
import 'package:realunit_wallet/screens/buy/cubits/buy_converter/buy_converter_cubit.dart';
import 'package:realunit_wallet/screens/buy/cubits/buy_payment_info/buy_payment_info_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/2fa/show_kyc_2fa_sheet.dart';
import 'package:realunit_wallet/setup/routing/routes/app_routes.dart';
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
            final state = paymentState as BuyPaymentInfoMinAmountNotMetFailure;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Column(
                spacing: 8.0,
                children: [
                  Text(
                    S
                        .of(context)
                        .buyMinAmount(
                          '${state.minAmount.round()}',
                          context.read<BuyConverterCubit>().state.currency.code,
                        ),
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
                    await context.pushNamed(AppRoutes.kyc);
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
                    await context.pushNamed(
                      AppRoutes.kyc,
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
          if (paymentState.error == PaymentInfoError.tfaRequired) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => showKyc2FaSheet(
                    context,
                    onVerified: () => context.read<BuyPaymentInfoCubit>().getPaymentInfo(
                      amount: amountController.text,
                    ),
                  ),
                  child: Text(S.of(context).twoFaVerify),
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
