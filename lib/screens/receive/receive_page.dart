import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/wallet/payment_uri.dart';
import 'package:realunit_wallet/screens/receive/widgets/qr_address_widget.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/widgets/handlebars.dart';

class ReceivePage extends StatelessWidget {
  const ReceivePage({super.key, this.isBottomSheet = true});

  final bool isBottomSheet;

  @override
  Widget build(BuildContext context) {
    final address = getIt<AppStore>().primaryAddress;

    return Scaffold(
      appBar: isBottomSheet
          ? null
          : AppBar(
              leading: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                ),
              ),
            ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (isBottomSheet) Handlebars.horizontal(context),
            SizedBox(
              width: double.infinity,
              height: isBottomSheet ? 20 : 0,
            ),
            QRAddressWidget(
              uri: EthereumURI(address: address, amount: '').toString(),
              subtitle: address,
            ),
          ],
        ),
      ),
    );
  }
}
