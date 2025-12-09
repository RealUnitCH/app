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
  })  : _amountController = amountController,
        _resultController = resultController;

  final TextEditingController _amountController;
  final TextEditingController _resultController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 12.0,
            vertical: 4.0,
          ),
          child: Text(
            S.of(context).you_pay,
            style: TextStyle(
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
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 14.0,
                      ),
                    ),
                    maxLines: 1,
                    onChanged: (value) => context.read<BuyConverterCubit>().onChfChanged(value),
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
                    padding: const EdgeInsets.only(
                      top: 8.0,
                      bottom: 8.0,
                      left: 10.0,
                      right: 4.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Currency.chf.code,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            height: 20 / 16,
                          ),
                        ),
                        Text(
                          Currency.chf.name,
                          style: TextStyle(
                            fontSize: 12,
                            height: 16 / 12,
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
        const SizedBox(height: 32),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 12.0,
            vertical: 4.0,
          ),
          child: Text(
            S.of(context).you_receive,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: RealUnitColors.neutral300),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _resultController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: false,
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
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
                    padding: const EdgeInsets.only(
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              realUnitAsset.symbol,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                height: 20 / 16,
                              ),
                            ),
                            Text(
                              realUnitAsset.name,
                              style: TextStyle(
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
      ],
    );
  }
}
