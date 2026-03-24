import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/models/balance.dart';
import 'package:realunit_wallet/packages/utils/asset_logo.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';
import 'package:realunit_wallet/screens/sell/cubits/sell_balance/sell_balance_cubit.dart';
import 'package:realunit_wallet/screens/sell/cubits/sell_converter/sell_converter_cubit.dart';
import 'package:realunit_wallet/screens/sell/widgets/sell_max_amount_button.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/currency.dart';

class SellConverter extends StatelessWidget {
  const SellConverter({
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
            S.of(context).youSell,
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
                  child: Stack(
                    children: [
                      TextField(
                        controller: _amountController,
                        keyboardType: const .numberWithOptions(decimal: false),
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          border: .none,
                          contentPadding: .symmetric(
                            horizontal: 10.0,
                            vertical: 14.0,
                          ),
                        ),
                        maxLines: 1,
                        onChanged: (value) =>
                            context.read<SellConverterCubit>().onSharesChanged(value),
                      ),
                      Positioned.fill(
                        child: Align(
                          alignment: .centerRight,
                          child: BlocBuilder<SellBalanceCubit, Balance>(
                            builder: (context, state) {
                              if (state.balance <= BigInt.zero) {
                                return const SizedBox.shrink();
                              }
                              return SellMaxAmountButton(
                                onTap: () {
                                  final maxStr = state.balance.toString();
                                  _amountController.text = maxStr;
                                  context.read<SellConverterCubit>().onSharesChanged(maxStr);
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ],
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
                        Column(
                          crossAxisAlignment: .start,
                          children: [
                            Text(
                              realUnitAsset.symbol,
                              style: const TextStyle(
                                fontWeight: .bold,
                                fontSize: 16,
                                height: 20 / 16,
                              ),
                            ),
                            Text(
                              realUnitAsset.name,
                              style: const TextStyle(
                                fontSize: 12,
                                height: 16 / 12,
                              ),
                            ),
                          ],
                        ),
                      ],
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
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: RealUnitColors.neutral300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _resultController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 14.0,
                      ),
                    ),
                    maxLines: 1,
                    onChanged: (value) => context.read<SellConverterCubit>().onFiatChanged(value),
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
                    child: BlocBuilder<SellConverterCubit, SellConverterState>(
                      builder: (context, state) {
                        return PopupMenuButton<Currency>(
                          initialValue: state.currency,
                          onSelected: (currency) {
                            if (currency == state.currency) return;
                            context.read<SellConverterCubit>().onCurrencyChanged(currency);
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
                            padding: const .only(
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
      ],
    );
  }
}
