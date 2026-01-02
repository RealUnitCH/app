import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/buy_payment_info_error.dart';
import 'package:realunit_wallet/screens/buy/cubits/buy_payment_info/buy_payment_info_cubit.dart';
import 'package:realunit_wallet/screens/buy/widgets/payment_action_required.dart';
import 'package:realunit_wallet/screens/buy/widgets/payment_information_details.dart';
import 'package:realunit_wallet/screens/registration/registration_page.dart';

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
          if (error == BuyPaymentInfoError.registrationRequired) {
            return PaymentActionRequired(
              title: 'Registrierung erforderlich',
              description: S.of(context).identity_check_description,
              onPressed: () async {
                await context.push(RegistrationPage.routeName);
                if (context.mounted) {
                  context.read<BuyPaymentInfoCubit>().getPaymentInfo();
                }
              },
            );
          } else if (error == BuyPaymentInfoError.kycRequired) {
            return PaymentActionRequired(
              title: S.of(context).identity_check_required,
              description:
                  'Der Betrag liegt über Ihrem Limit. Um dieses zu erhöhen, bestätigen Sie bitte Ihre Identität (KYC) über DFX.',
              onPressed: () {},
            );
          }
          return PaymentActionRequired(
            title: 'Unbekannter Fehler',
            description:
                'Es ist ein unbekannter Fehler aufgetreten. Bitte melde dich beim Support.',
          );
        }
        return SizedBox.shrink();
      },
    );
  }
}
