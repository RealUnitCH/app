import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/wallet/payment_uri.dart';
import 'package:realunit_wallet/screens/receive/widgets/qr_address_widget.dart';

class SettingsAddressPage extends StatelessWidget {
  const SettingsAddressPage({super.key});

  @override
  Widget build(BuildContext context) {
    final address = getIt<AppStore>().primaryAddress;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet-Addresse'),
      ),
      body: Center(
        child: Padding(
          padding: const .symmetric(horizontal: 20.0, vertical: 12.0),
          child: SafeArea(
            child: Column(
              spacing: 40.0,
              mainAxisAlignment: .center,
              children: [
                const SizedBox(height: 20.0),
                Column(
                  spacing: 12.0,
                  children: [
                    SvgPicture.asset(
                      'assets/images/coins/REALU.svg',
                      width: 70,
                      height: 70,
                    ),
                    Text(
                      'REALU Addresse',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
                QRAddressWidget(
                  uri: EthereumURI(address: address, amount: '').toString(),
                  subtitle: address,
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
