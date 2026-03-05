import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/wallet/payment_uri.dart';
import 'package:realunit_wallet/screens/receive/widgets/qr_address_widget.dart';
import 'package:realunit_wallet/styles/colors.dart';

class SettingsWalletAddressPage extends StatelessWidget {
  const SettingsWalletAddressPage({super.key});

  @override
  Widget build(BuildContext context) {
    final walletAddress = getIt<AppStore>().primaryAddress;

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).walletAddress),
      ),
      body: Center(
        child: Padding(
          padding: const .symmetric(
            horizontal: 20.0,
            vertical: 12.0,
          ),
          child: SingleChildScrollView(
            child: SafeArea(
              child: Column(
                spacing: 40.0,
                mainAxisAlignment: .center,
                children: [
                  Column(
                    spacing: 12.0,
                    children: [
                      SvgPicture.asset(
                        'assets/images/coins/REALU.svg',
                        width: 70,
                        height: 70,
                      ),
                      Text(
                        '${S.of(context).realunitWallet} ${S.of(context).address}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                  QRAddressWidget(
                    uri: EthereumURI(address: walletAddress, amount: '').toString(),
                    subtitle: walletAddress,
                  ),
                  Padding(
                    padding: const .all(20.0),
                    child: Text(
                      S.of(context).walletAddressDisclaimer,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: RealUnitColors.neutral500,
                      ),
                      textAlign: .center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
