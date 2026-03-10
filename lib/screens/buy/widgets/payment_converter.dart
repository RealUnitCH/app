import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/utils/asset_logo.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';
import 'package:realunit_wallet/screens/buy/cubits/buy_converter/buy_converter_cubit.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/currency.dart';

class PaymentConverter extends StatelessWidget {
  const PaymentConverter({
    super.key,
    required TextEditingController amountController,
    required TextEditingController resultController,
  }) : _amountController = amountController,
       _resultController = resultController;

  final TextEditingController _amountController;
  final TextEditingController _resultController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Padding(
          padding: const .symmetric(
            horizontal: 12.0,
            vertical: 4.0,
          ),
          child: Text(
            S.of(context).youPay,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: .bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: .circular(8.0),
            border: Border.all(color: RealUnitColors.neutral300),
          ),
          child: ClipRRect(
            borderRadius: .circular(8.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const .numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                    decoration: const InputDecoration(
                      border: .none,
                      contentPadding: .symmetric(
                        horizontal: 10.0,
                        vertical: 14.0,
                      ),
                    ),
                    maxLines: 1,
                    onChanged: (value) => context.read<BuyConverterCubit>().onFiatChanged(value),
                  ),
                ),
                Container(
                  color: RealUnitColors.neutral300,
                  width: 1,
                  height: 52,
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    color: RealUnitColors.neutral50,
                    child: BlocBuilder<BuyConverterCubit, BuyConverterState>(
                      builder: (context, state) {
                        return PopupMenuButton<Currency>(
                          initialValue: state.currency,
                          onSelected: (currency) {
                            if (currency == state.currency) return;
                            context.read<BuyConverterCubit>().onCurrencyChanged(currency);
                          },
                          itemBuilder: (context) => Currency.values.map((currency) {
                            return PopupMenuItem(
                              value: currency,
                              child: Column(
                                mainAxisSize: .min,
                                crossAxisAlignment: .start,
                                children: [
                                  Text(
                                    currency.code,
                                    overflow: .ellipsis,
                                    style:
                                        Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.copyWith(
                                          fontWeight: .bold,
                                        ),
                                  ),
                                  Text(
                                    currency.name,
                                    overflow: .ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: 8.0,
                              bottom: 8.0,
                              left: 10.0,
                              right: 4.0,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    mainAxisSize: .min,
                                    crossAxisAlignment: .start,
                                    children: [
                                      Text(
                                        state.currency.code,
                                        overflow: .ellipsis,
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodyLarge?.copyWith(
                                              fontWeight: .bold,
                                            ),
                                      ),
                                      Text(
                                        state.currency.name,
                                        overflow: .ellipsis,
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const .symmetric(
            horizontal: 12.0,
            vertical: 4.0,
          ),
          child: Text(
            S.of(context).youReceive,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: .bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: .all(color: RealUnitColors.neutral300),
            borderRadius: .circular(8.0),
          ),
          child: ClipRRect(
            borderRadius: .circular(8.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _resultController,
                    keyboardType: const .numberWithOptions(
                      decimal: false,
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      border: .none,
                      contentPadding: .symmetric(
                        horizontal: 10.0,
                        vertical: 14.0,
                      ),
                    ),
                    maxLines: 1,
                    onChanged: (value) => context.read<BuyConverterCubit>().onSharesChanged(value),
                  ),
                ),
                Container(
                  color: RealUnitColors.neutral300,
                  width: 1,
                  height: 52,
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    color: RealUnitColors.neutral50,
                    padding: const .only(
                      top: 8.0,
                      bottom: 8.0,
                      left: 10.0,
                      right: 4.0,
                    ),
                    child: Row(
                      spacing: 8,
                      children: [
                        Image.asset(
                          getAssetImagePath(realUnitAsset),
                          height: 24,
                          width: 24,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: .start,
                            children: [
                              Text(
                                realUnitAsset.symbol,
                                overflow: .ellipsis,
                                style:
                                    Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.copyWith(
                                      fontWeight: .bold,
                                    ),
                              ),
                              Text(
                                realUnitAsset.name,
                                overflow: .ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
