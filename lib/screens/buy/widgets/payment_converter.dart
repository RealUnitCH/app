import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/utils/asset_logo.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';
import 'package:realunit_wallet/screens/buy/cubit/buy_converter/buy_converter_cubit.dart';
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
        const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 12.0,
            vertical: 4.0,
          ),
          child: Text(
            'Du bezahlst',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: RealUnitColors.neutral400),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
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
                color: RealUnitColors.neutral400,
                width: 1,
                height: 52,
                margin: const EdgeInsets.symmetric(horizontal: 10.0),
              ),
              Expanded(
                flex: 2,
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
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 12.0,
            vertical: 4.0,
          ),
          child: Text(
            'Du erhältst',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: RealUnitColors.neutral400),
            borderRadius: BorderRadius.circular(8.0),
          ),
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
                color: RealUnitColors.neutral400,
                width: 1,
                height: 52,
                margin: const EdgeInsets.symmetric(horizontal: 10.0),
              ),
              Expanded(
                flex: 2,
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
            ],
          ),
        ),
      ],
    );
  }
}
