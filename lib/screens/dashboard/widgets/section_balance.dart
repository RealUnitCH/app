import 'dart:developer' as developer;

import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/open_crypto_pay/exceptions.dart';
import 'package:realunit_wallet/packages/open_crypto_pay/open_crypto_pay_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_service.dart';
import 'package:realunit_wallet/packages/wallet/payment_uri.dart';
import 'package:realunit_wallet/screens/receive/receive_page.dart';
import 'package:realunit_wallet/screens/send/send_page.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/styles.dart';
import 'package:realunit_wallet/widgets/action_button.dart';
import 'package:realunit_wallet/widgets/hide_amount_text.dart';
import 'package:realunit_wallet/widgets/qr_scanner.dart';
import 'package:realunit_wallet/widgets/vertical_icon_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SectionBalance extends StatelessWidget {
  final BigInt balance;
  final VoidCallback onHideAmountPress;
  final bool isFiatServiceAvailable;
  final VoidCallback onDepositPress;
  final VoidCallback onWithdrawPress;

  const SectionBalance({
    super.key,
    required this.balance,
    required this.onHideAmountPress,
    required this.isFiatServiceAvailable,
    required this.onDepositPress,
    required this.onWithdrawPress,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: RealUnitColors.realUnitBlue,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(left: 16, right: 16, top: 10),
                child: Row(
                  children: [
                    if (isFiatServiceAvailable) ...[
                      Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: ActionButton(
                          icon: Icons.credit_card,
                          label: S.of(context).deposit,
                          onPressed: () =>
                              getIt<DFXService>().launchProvider(context, true),
                          buttonStyle: kBalanceBarActionButtonStyle,
                        ),
                      ),
                      ActionButton(
                        icon: Icons.account_balance,
                        label: S.of(context).withdraw,
                        onPressed: () =>
                            getIt<DFXService>().launchProvider(context, false),
                        buttonStyle: kBalanceBarActionButtonStyle,
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 12, bottom: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          S.of(context).balance,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withAlpha(153),
                          ),
                        ),
                        InkWell(
                          onTap: onHideAmountPress,
                          enableFeedback: false,
                          child: Padding(
                            padding: EdgeInsets.only(left: 5),
                            child: BlocBuilder<SettingsBloc, SettingsState>(
                              builder: (context, state) => Icon(
                                state.hideAmounts
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                size: 14,
                                color: Colors.white.withAlpha(153),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    HideAmountText(
                      amount: balance,
                      style: const TextStyle(
                          fontSize: 35,
                          color: Colors.white,
                          fontFamily: "Satoshi Bold"),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  VerticalIconButton(
                    onPressed: () => showCupertinoSheet(
                        context: context, pageBuilder: (_) => ReceivePage()),
                    icon: const Icon(Icons.arrow_downward, color: Colors.white),
                    label: S.of(context).receive,
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 15, right: 15),
                    child: VerticalIconButton.extended(
                      onPressed: () => _presentQRReader(context),
                      icon: const Icon(Icons.qr_code, color: Colors.white),
                      label: S.of(context).pay_scan,
                    ),
                  ),
                  VerticalIconButton(
                    onPressed: () => context.push("/send"),
                    icon: const Icon(Icons.arrow_upward, color: Colors.white),
                    label: S.of(context).send,
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );

  Future<void> _presentQRReader(BuildContext context) async {
    QRData? result = await presentQRScanner(
      context,
      (code, _) =>
          RegExp(r'(\b0x[a-fA-F0-9]{40}\b)').hasMatch(code ?? '') ||
          OpenCryptoPayService.isOpenCryptoPayQR(code ?? ''),
    );

    if (result?.value == null) return;

    if (OpenCryptoPayService.isOpenCryptoPayQR(result!.value!)) {
      try {
        final res = await getIt<OpenCryptoPayService>()
            .getOpenCryptoPayInvoice(result.value!);
        if (context.mounted) {
          context.push("/send/openCryptoPay", extra: res);
        }
      } on OpenCryptoPayException catch (e) {
        developer.log('Error during Open CryptoPay',
            error: e, name: 'SectionBalance._presentQRReader');
      }
    } else if (result.value!.startsWith("0x")) {
      if (context.mounted) {
        context.push("/send", extra: SendRouteParams(receiver: result.value!));
      }
    } else {
      final uri = ERC681URI.fromString(result.value!);
      if (context.mounted) {
        context.push("/send",
            extra: SendRouteParams(receiver: uri.address, amount: uri.amount));
      }
    }
  }
}
