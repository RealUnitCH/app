import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/screens/buy/cubits/buy_allowlist/buy_allowlist_cubit.dart';
import 'package:realunit_wallet/screens/registration/registration_page.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/styles.dart';

class PaymentKycRequired extends StatelessWidget {
  const PaymentKycRequired({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 20,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          spacing: 12,
          children: [
            Icon(
              Icons.info,
              size: 16,
              color: RealUnitColors.realUnitBlue,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Identitätsprüfung erforderlich',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 18 / 14,
                    ),
                  ),
                  Text(
                    'Um fortzufahren, bestätigen Sie bitte Ihre Identität (KYC) über DFX. Dabei entsteht eine Geschäftsbeziehung mit RealUnit AG und DFX AG. Die Identitätsprüfung gilt für beide.',
                    style: TextStyle(
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
        TextButton(
          onPressed: () async {
            await context.push(RegistrationPage.routeName);
            if (context.mounted) context.read<BuyAllowlistCubit>().checkAddress();
          },
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(
              RealUnitColors.realUnitBlue,
            ),
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(
                vertical: 10.0,
                horizontal: 20.0,
              ),
            ),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(60.0),
              ),
            ),
          ),
          child: Text(
            'Identität bestätigen',
            textAlign: TextAlign.center,
            style: kFullwidthBlueButtonTextStyle,
          ),
        ),
      ],
    );
  }
}
