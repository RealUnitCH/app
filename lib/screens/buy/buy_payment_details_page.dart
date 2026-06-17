import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/buy/buy_payment_info.dart';
import 'package:realunit_wallet/screens/buy/widgets/payment_details_card.dart';
import 'package:realunit_wallet/setup/routing/routes/app_routes.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';

/// Arguments for the `Zahlungsdetails` page, passed via the GoRouter `extra`
/// slot. The buy quote ([buyPaymentInfo]) and the committed [amount] are
/// produced on the buy page; [reference] is the order reference returned by
/// the confirm call that made the purchase binding.
class BuyPaymentDetailsParams {
  final BuyPaymentInfo buyPaymentInfo;
  final String amount;
  final String reference;

  const BuyPaymentDetailsParams({
    required this.buyPaymentInfo,
    required this.amount,
    required this.reference,
  });
}

/// Shown after a buy is confirmed and binding. Surfaces the bank-transfer
/// instructions the backend has also emailed to the user, stresses the
/// purpose-of-payment requirement, and closes the flow with a return to the
/// main area.
class BuyPaymentDetailsPage extends StatelessWidget {
  final BuyPaymentDetailsParams params;

  const BuyPaymentDetailsPage({super.key, required this.params});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).buyPaymentDetailsTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 0.0),
            child: Column(
              crossAxisAlignment: .start,
              spacing: 16.0,
              children: [
                Text(
                  S.of(context).buyPaymentInstructionEmail,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Row(
                  spacing: 12,
                  crossAxisAlignment: .start,
                  children: [
                    const Icon(
                      Icons.info,
                      size: 24,
                      color: RealUnitColors.realUnitBlue,
                    ),
                    Expanded(
                      child: Text(
                        S.of(context).buyPaymentPurposeHint,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                if (params.reference.isNotEmpty)
                  Row(
                    spacing: 8.0,
                    children: [
                      Text(
                        '${S.of(context).buyExecutedReference}: ${params.reference}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: .w600,
                        ),
                      ),
                      InkWell(
                        onTap: () => Clipboard.setData(
                          ClipboardData(text: params.reference),
                        ),
                        child: const Icon(
                          Icons.copy_outlined,
                          color: RealUnitColors.realUnitBlue,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                PaymentDetailsCard(
                  buyPaymentInfo: params.buyPaymentInfo,
                  amount: params.amount,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: AppFilledButton(
                    onPressed: () => context.goNamed(AppRoutes.home),
                    label: S.of(context).buyBackToMain,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
