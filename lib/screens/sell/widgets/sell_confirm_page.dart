import 'package:flutter/material.dart';
import 'package:realunit_wallet/packages/service/dfx/models/sell/sell_payment_info.dart';

class SellConfirmPage extends StatelessWidget {
  final SellPaymentInfo paymentInfo;

  const SellConfirmPage({super.key, required this.paymentInfo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Verkauf bestätigen',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
