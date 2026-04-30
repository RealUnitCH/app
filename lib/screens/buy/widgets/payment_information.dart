import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/payment_info_error.dart';
import 'package:realunit_wallet/screens/buy/cubits/buy_payment_info/buy_payment_info_cubit.dart';
import 'package:realunit_wallet/screens/buy/widgets/payment_action_required.dart';
import 'package:realunit_wallet/screens/buy/widgets/payment_information_details.dart';

class PaymentInformation extends StatelessWidget {
  final String amount;

  const PaymentInformation({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BuyPaymentInfoCubit, BuyPaymentInfoState>(
      builder: (context, paymentInfoState) {
        if (paymentInfoState is BuyPaymentInfoSuccess) {
          return PaymentInformationDetails(
            amount: amount,
            buyPaymentInfo: paymentInfoState.buyPaymentInfo,
          );
        }
        if (paymentInfoState is BuyPaymentInfoLoading) {
          return const Center(
            child: CupertinoActivityIndicator(),
          );
        }
        if (paymentInfoState is BuyPaymentInfoFailure) {
          final error = paymentInfoState.error;
          if (error == PaymentInfoError.registrationRequired) {
            return PaymentActionRequired(
              title: S.of(context).registrationRequired,
              description: S.of(context).registrationRequiredDescription,
            );
          } else if (error == PaymentInfoError.kycRequired) {
            return PaymentActionRequired(
              title: S.of(context).identityCheckRequired,
              description: S.of(context).identityCheckDescription,
            );
          } else if (error == PaymentInfoError.unknown) {
            return PaymentActionRequired(
              title: S.of(context).paymentInformationFailed,
              description: S.of(context).paymentInformationFailedDescription,
            );
          }
        }
        return const SizedBox.shrink();
      },
    );
  }
}
