import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/models/price_point.dart';
import 'package:realunit_wallet/packages/utils/format_fixed.dart';
import 'package:realunit_wallet/screens/dashboard/widgets/price_chart.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/styles/colors.dart';

class PriceWidget extends StatelessWidget {
  final BigInt price;
  final List<PricePoint> priceChart;

  const PriceWidget({
    super.key,
    required this.price,
    required this.priceChart,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 8),
        width: double.infinity,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, left: 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          S.of(context).realunitStockprice,
                          style: const TextStyle(
                            fontSize: 12,
                            color: RealUnitColors.neutral400,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BlocBuilder<SettingsBloc, SettingsState>(
                          builder: (context, state) {
                            return Text(
                              state.currency.code.toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: RealUnitColors.realUnitBlack),
                            );
                          },
                        ),
                        Text(
                          formatFixed(price, 2, trimZeros: false),
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                            color: RealUnitColors.realUnitBlack,
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
              SizedBox(
                height: 135,
                child: PriceChart(
                  prices: priceChart,
                ),
              )
            ],
          ),
        ),
      );
}
