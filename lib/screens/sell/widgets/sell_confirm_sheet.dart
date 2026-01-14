import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/sell_payment_info.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_sell_payment_info_service.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';
import 'package:realunit_wallet/screens/sell/cubits/sell_confirm/sell_confirm_cubit.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/handlebars.dart';

class SellConfirmSheet extends StatelessWidget {
  final SellPaymentInfo paymentInfo;

  const SellConfirmSheet({super.key, required this.paymentInfo});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SellConfirmCubit(
        getIt<RealUnitSellPaymentInfoService>(),
      ),
      child: SellConfirmSheetView(
        paymentInfo: paymentInfo,
      ),
    );
  }
}

class SellConfirmSheetView extends StatelessWidget {
  final SellPaymentInfo paymentInfo;

  const SellConfirmSheetView({super.key, required this.paymentInfo});

  @override
  Widget build(BuildContext context) {
    return BlocListener<SellConfirmCubit, SellConfirmState>(
      listener: (context, state) async {
        if (state is SellConfirmFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error),
              backgroundColor: RealUnitColors.status.red600,
            ),
          );
        }
        if (state is SellConfirmSuccess) {
          context.pop(true);
        }
      },
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Handlebars.horizontal(context, margin: const EdgeInsets.only(top: 5), width: 36),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Text(
                    S.of(context).sellReviewAndConfirm,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: RealUnitColors.neutral200),
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _withDividers(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12.0,
                            horizontal: 20.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                realUnitAsset.symbol,
                                style: const TextStyle(
                                  color: RealUnitColors.neutral500,
                                  height: 18 / 14,
                                ),
                              ),
                              Text(
                                '${paymentInfo.amount}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  height: 18 / 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12.0,
                            horizontal: 20.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${S.of(context).amountIn} ${paymentInfo.currency.code}',
                                style: const TextStyle(
                                  color: RealUnitColors.neutral500,
                                  height: 18 / 14,
                                ),
                              ),
                              Text(
                                '${paymentInfo.estimatedAmount}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  height: 18 / 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12.0,
                            horizontal: 20.0,
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    S.of(context).receiver,
                                    style: const TextStyle(
                                      color: RealUnitColors.neutral500,
                                      height: 18 / 14,
                                    ),
                                  ),
                                  Text(
                                    paymentInfo.beneficiary.iban,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      height: 18 / 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: BlocBuilder<SellConfirmCubit, SellConfirmState>(
                    builder: (context, state) {
                      final isLoading = state is SellConfirmLoading;
                      if (isLoading) {
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
                          label: Text(S.of(context).confirm),
                        );
                      }
                      return FilledButton(
                        onPressed: () =>
                            context.read<SellConfirmCubit>().confirmPayment(paymentInfo),
                        child: Text(S.of(context).confirm),
                      );
                    },
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _withDividers({required List<Widget> children}) {
    final result = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i < children.length - 1) {
        result.add(
          const Divider(
            color: RealUnitColors.neutral200,
          ),
        );
      }
    }
    return result;
  }
}
