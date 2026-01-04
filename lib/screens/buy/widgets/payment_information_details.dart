import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/buy_payment_info.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_buy_payment_info_service.dart';
import 'package:realunit_wallet/screens/buy/widgets/payment_executed_sheet.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/styles.dart';

class PaymentInformationDetails extends StatefulWidget {
  final String amount;
  final BuyPaymentInfo buyPaymentInfo;

  const PaymentInformationDetails({super.key, required this.buyPaymentInfo, required this.amount});

  @override
  State<PaymentInformationDetails> createState() => _PaymentInformationDetailsState();
}

class _PaymentInformationDetailsState extends State<PaymentInformationDetails> {
  bool _isConfirming = false;

  Future<void> _confirmPayment() async {
    setState(() => _isConfirming = true);

    try {
      await getIt<RealUnitBuyPaymentInfoService>().confirmPayment(widget.buyPaymentInfo.id);

      if (mounted) {
        await showModalBottomSheet(
          context: context,
          builder: (context) => PaymentExecutedSheet(),
        );
        if (context.mounted) context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      description: '${S.of(context).amount_in} ${widget.buyPaymentInfo.currency.code}',
                      value: widget.amount,
                    ),
                    _PaymentInformationDetailsRow(
                      description: S.of(context).iban,
                      value: widget.buyPaymentInfo.iban,
                    ),
                    _PaymentInformationDetailsRow(
                      description: S.of(context).bic,
                      value: widget.buyPaymentInfo.bic,
                    ),
                    _PaymentInformationDetailsRow(
                      title: S.of(context).receiver,
                      description: S.of(context).name,
                      value: widget.buyPaymentInfo.name,
                    ),
                    _PaymentInformationDetailsRow(
                      description: S.of(context).address,
                      value: '${widget.buyPaymentInfo.street} ${widget.buyPaymentInfo.number}',
                    ),
                    _PaymentInformationDetailsRow(
                      description: S.of(context).postcode_abr,
                      value: widget.buyPaymentInfo.zip,
                    ),
                    _PaymentInformationDetailsRow(
                      description: S.of(context).location,
                      value: widget.buyPaymentInfo.city,
                    ),
                    _PaymentInformationDetailsRow(
                      description: S.of(context).country,
                      value: widget.buyPaymentInfo.country,
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
              onPressed: _isConfirming ? null : _confirmPayment,
              style: ButtonStyle(
                padding: WidgetStateProperty.resolveWith(
                  (states) => const EdgeInsets.symmetric(
                    vertical: 10.0,
                    horizontal: 20.0,
                  ),
                ),
              ),
              child: _isConfirming
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
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
