import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/bank_account.dart';
import 'package:realunit_wallet/screens/sell/cubits/sell_payment_info/sell_payment_info_cubit.dart';
import 'package:realunit_wallet/screens/sell/widgets/sell_confirm_sheet.dart';
import 'package:realunit_wallet/styles/colors.dart';

class SellButton extends StatelessWidget {
  final String amount;
  final BankAccount? bankAccount;

  const SellButton({super.key, required this.amount, required this.bankAccount});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SellPaymentInfoCubit, SellPaymentInfoState>(
      listener: (context, state) async {
        if (state is SellPaymentInfoFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: RealUnitColors.status.red600,
            ),
          );
        }
        if (state is SellPaymentInfoSuccess) {
          await showModalBottomSheet(
            isScrollControlled: true,
            context: context,
            builder: (_) => SellConfirmSheet(
              paymentInfo: state.sellPaymentInfo,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is SellPaymentInfoLoading) {
          return FilledButton.icon(
            onPressed: null,
            icon: SizedBox(
              height: 14,
              width: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: RealUnitColors.basic.black.withValues(alpha: 0.5),
              ),
            ),
            label: Text('$amount ${S.of(context).sell_realu}'),
          );
        }
        if (bankAccount != null && amount.isNotEmpty) {
          return FilledButton(
            onPressed: () => context.read<SellPaymentInfoCubit>().getPaymentInfo(
                  amount: amount,
                  iban: bankAccount!.iban,
                ),
            child: Text('$amount ${S.of(context).sell_realu}'),
          );
        }
        return FilledButton(
          onPressed: null,
          child: Text('$amount ${S.of(context).sell_realu}'),
        );
      },
    );
  }
}
