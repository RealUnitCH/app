import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/widgets/amount_info_row.dart';
import 'package:realunit_wallet/widgets/handlebars.dart';
import 'package:realunit_wallet/widgets/standard_slide_button_widget.dart';
import 'package:flutter/material.dart';

class ConfirmBottomSheet extends StatelessWidget {
  const ConfirmBottomSheet({
    super.key,
    required this.title,
    required this.onConfirm,
    this.message,
    this.fee,
    this.feeSymbol,
  });

  final String title;
  final String? message;
  final String? fee;
  final String? feeSymbol;

  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(left: 10, right: 10, top: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 5, bottom: 16),
                  child: Handlebars.horizontal(context),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                if (message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 10),
                    child: Text(
                      message!,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                if (fee != null)
                  AmountInfoRow(
                    title: S.of(context).fee,
                    amountString: fee!,
                    currencySymbol: feeSymbol!,
                  ),
                Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 10),
                  child: StandardSlideButton(
                    buttonText: S.of(context).confirm,
                    onSlideComplete: onConfirm,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
