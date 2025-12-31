import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/buy/cubits/buy_payment_info/buy_payment_info_cubit.dart';
import 'package:realunit_wallet/screens/buy/widgets/payment_executed_sheet.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/styles.dart';

class PaymentInformation extends StatelessWidget {
  const PaymentInformation({
    super.key,
    required String amount,
  }) : _amount = amount;

  final String _amount;

  @override
  Widget build(BuildContext context) {
    final buyPaymentInfo = context.read<BuyPaymentInfoCubit>().state.buyPaymentInfo;

    if (buyPaymentInfo != null) {
      return Column(
        children: [
          Text(
            S.of(context).buy_payment_information,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Row(
            spacing: 12,
            children: [
              Icon(
                Icons.info,
                size: 16,
                color: RealUnitColors.realUnitBlue,
              ),
              Expanded(
                child: Text(
                  S.of(context).buy_payment_information_description,
                  style: TextStyle(
                    fontSize: 14,
                    height: 18 / 14,
                    letterSpacing: 0.0,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: BoxBorder.all(
                    width: 1,
                    color: RealUnitColors.neutral200,
                  ),
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Column(
                  children: _withDividers(
                    children: [
                      _PaymentInformationDetailsRow(
                        description: '${S.of(context).amount_in} ${buyPaymentInfo.currency.code}',
                        value: _amount,
                      ),
                      _PaymentInformationDetailsRow(
                        description: S.of(context).iban,
                        value: buyPaymentInfo.iban,
                      ),
                      _PaymentInformationDetailsRow(
                        description: S.of(context).bic,
                        value: buyPaymentInfo.bic,
                      ),
                      _PaymentInformationDetailsRow(
                        title: S.of(context).receiver,
                        description: S.of(context).name,
                        value: buyPaymentInfo.name,
                      ),
                      _PaymentInformationDetailsRow(
                        description: S.of(context).address,
                        value: '${buyPaymentInfo.street} ${buyPaymentInfo.number}',
                      ),
                      _PaymentInformationDetailsRow(
                        description: S.of(context).postcode_abr,
                        value: buyPaymentInfo.zip,
                      ),
                      _PaymentInformationDetailsRow(
                        description: S.of(context).location,
                        value: buyPaymentInfo.city,
                      ),
                      _PaymentInformationDetailsRow(
                        description: S.of(context).country,
                        value: buyPaymentInfo.country,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 20),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  await showModalBottomSheet(
                    context: context,
                    builder: (context) => PaymentExecutedSheet(),
                  );
                  if (context.mounted) context.pop();
                },
                style: ButtonStyle(
                  padding: WidgetStateProperty.resolveWith(
                    (states) => const EdgeInsets.symmetric(
                      vertical: 10.0,
                      horizontal: 20.0,
                    ),
                  ),
                ),
                child: Text(
                  S.of(context).buy_payment_confirm,
                  textAlign: TextAlign.center,
                  style: kFullwidthBlueButtonTextStyle,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Center(
      child: Text(
        S.of(context).buy_payment_information_not_available,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
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
          Divider(
            color: RealUnitColors.neutral200,
          ),
        );
      }
    }
    return result;
  }
}

class _PaymentInformationDetailsRow extends StatelessWidget {
  const _PaymentInformationDetailsRow({
    this.title,
    required this.description,
    required this.value,
  });

  final String? title;
  final String description;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20.0,
        vertical: 12.0,
      ),
      child: Column(
        spacing: 20.0,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Text(
              title!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                height: 18 / 14,
                letterSpacing: 0.0,
              ),
            ),
          Row(
            spacing: 12.0,
            children: [
              Text(
                description,
                style: TextStyle(
                  color: RealUnitColors.realUnitBlue,
                  fontSize: 14,
                  height: 18 / 14,
                  letterSpacing: 0.0,
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    height: 18 / 14,
                    letterSpacing: 0.0,
                  ),
                ),
              ),
              InkWell(
                child: Icon(
                  Icons.copy_outlined,
                  color: RealUnitColors.realUnitBlue,
                  fontWeight: FontWeight.bold,
                  size: 16,
                ),
                onTap: () => Clipboard.setData(
                  ClipboardData(
                    text: value,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
