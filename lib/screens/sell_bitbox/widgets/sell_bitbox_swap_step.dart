import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/sell_payment_info.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';
import 'package:realunit_wallet/screens/sell_bitbox/cubit/sell_bitbox_cubit.dart';
import 'package:realunit_wallet/styles/colors.dart';

class SellBitboxSwapStep extends StatelessWidget {
  final SellPaymentInfo paymentInfo;

  const SellBitboxSwapStep({super.key, required this.paymentInfo});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SellBitboxCubit, SellBitboxState>(
      builder: (context, state) {
        if (state is SellBitboxPreparingSwap) {
          return const Column(
            mainAxisAlignment: .center,
            children: [CupertinoActivityIndicator()],
          );
        }
        if (state is SellBitboxAwaitingSwapConfirm) {
          return Column(
            mainAxisAlignment: .center,
            spacing: 24,
            children: [
              Text(
                S.of(context).sellBitboxSwapTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: .bold,
                ),
                textAlign: .center,
              ),
              Container(
                decoration: BoxDecoration(
                  border: .all(color: RealUnitColors.neutral200),
                  borderRadius: .circular(16),
                ),
                child: Column(
                  children: [
                    _row(
                      context,
                      label: S.of(context).sellBitboxSwapFrom,
                      value: '${paymentInfo.amount} ${realUnitAsset.symbol}',
                    ),
                    const Divider(color: RealUnitColors.neutral200, height: 1),
                    _row(
                      context,
                      label: S.of(context).sellBitboxSwapTo,
                      value: '≈ ${paymentInfo.estimatedAmount.toStringAsFixed(2)} ZCHF',
                    ),
                  ],
                ),
              ),
              Text(
                S.of(context).sellBitboxSwapDescription,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: RealUnitColors.neutral500,
                ),
                textAlign: .center,
              ),
              FilledButton(
                onPressed: () => context.read<SellBitboxCubit>().confirmSwap(),
                child: Text(S.of(context).confirm),
              ),
            ],
          );
        }
        if (state is SellBitboxSwapping) {
          return Column(
            mainAxisAlignment: .center,
            spacing: 24,
            children: [
              const CupertinoActivityIndicator(),
              Text(
                S.of(context).sellBitboxSwapping,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: .center,
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _row(BuildContext context, {required String label, required String value}) {
    return Padding(
      padding: const .symmetric(vertical: 12, horizontal: 20),
      child: Row(
        mainAxisAlignment: .spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: RealUnitColors.neutral500,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: .w600,
            ),
          ),
        ],
      ),
    );
  }
}
