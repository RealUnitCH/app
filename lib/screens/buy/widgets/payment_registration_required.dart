import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/buy/cubits/buy_payment_info/buy_payment_info_cubit.dart';
import 'package:realunit_wallet/screens/registration/registration_page.dart';
import 'package:realunit_wallet/styles/colors.dart';

class PaymentRegistrationRequired extends StatelessWidget {
  const PaymentRegistrationRequired({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 20,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          spacing: 12,
          children: [
            const Icon(
              Icons.info,
              size: 16,
              color: RealUnitColors.realUnitBlue,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.of(context).identityCheckRequired,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 18 / 14,
                    ),
                  ),
                  Text(
                    S.of(context).identityCheckDescription,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 18 / 14,
                      letterSpacing: 0.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        FilledButton(
          onPressed: () async {
            await context.push(RegistrationPage.routeName);
            if (context.mounted) context.read<BuyPaymentInfoCubit>().getPaymentInfo();
          },
          child: Text(
            S.of(context).identityConfirm,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
