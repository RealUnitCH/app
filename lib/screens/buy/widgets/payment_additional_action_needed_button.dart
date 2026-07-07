import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/payment_info_error.dart';
import 'package:realunit_wallet/screens/buy/cubits/buy_converter/buy_converter_cubit.dart';
import 'package:realunit_wallet/screens/buy/cubits/buy_payment_info/buy_payment_info_cubit.dart';
import 'package:realunit_wallet/screens/hardware_connect_bitbox/show_bitbox_reconnect_sheet.dart';
import 'package:realunit_wallet/setup/routing/routes/app_routes.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';

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
                          '${state.minAmount.ceil()}',
                          context.read<BuyConverterCubit>().state.currency.code,
                        ),
                    style: const TextStyle(
                      color: RealUnitColors.neutral500,
                      fontSize: 14,
                    ),
                  ),
                  AppFilledButton(
                    onPressed: null,
                    label: S.of(context).next,
                  ),
                ],
              ),
            );
          }
          if (paymentState.error == PaymentInfoError.registrationRequired) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: AppFilledButton(
                onPressed: () async {
                  await context.pushNamed(AppRoutes.kyc);
                  if (context.mounted) {
                    context.read<BuyPaymentInfoCubit>().getPaymentInfo(
                      amount: amountController.text,
                      currency: context.read<BuyConverterCubit>().state.currency,
                    );
                  }
                },
                label: S.of(context).next,
              ),
            );
          }
          if (paymentState.error == PaymentInfoError.kycRequired) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: AppFilledButton(
                onPressed: () async {
                  await context.pushNamed(AppRoutes.kyc);
                  if (context.mounted) {
                    context.read<BuyPaymentInfoCubit>().getPaymentInfo(
                      amount: amountController.text,
                      currency: context.read<BuyConverterCubit>().state.currency,
                    );
                  }
                },
                label: S.of(context).next,
              ),
            );
          }
          if (paymentState.error == PaymentInfoError.bitboxDisconnected) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: AppFilledButton(
                onPressed: () async {
                  final paymentInfoCubit = context.read<BuyPaymentInfoCubit>();
                  final converterCubit = context.read<BuyConverterCubit>();
                  await showBitboxReconnectSheet(context);
                  paymentInfoCubit.getPaymentInfo(
                    amount: amountController.text,
                    currency: converterCubit.state.currency,
                  );
                },
                label: S.of(context).bitboxReconnect,
              ),
            );
          }
          if (paymentState.error == PaymentInfoError.unknown) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: AppFilledButton(
                onPressed: () => context.read<BuyPaymentInfoCubit>().getPaymentInfo(
                  amount: amountController.text,
                  currency: context.read<BuyConverterCubit>().state.currency,
                ),
                label: S.of(context).retry,
              ),
            );
          }
        }
        return const SizedBox.shrink();
      },
    );
  }
}
