import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/utils/device_info.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/qr_scanner.dart';
import 'package:realunit_wallet/widgets/vertical_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ActionBar extends StatelessWidget {
  const ActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.only(bottom: 24),
      child: Wrap(
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(left: 16, right: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50.0),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50.0),
                  border: Border.all(
                    color: DEuroColors.dEuroGold,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: VerticalIconButton(
                        onPressed: () => context.push("/receive"),
                        icon: const Icon(
                          Icons.arrow_downward,
                          color: DEuroColors.dEuroGold,
                        ),
                        label: S.of(context).receive,
                      ),
                    ),
                    if (DeviceInfo.instance.isMobile)
                      Expanded(
                        child: VerticalIconButton(
                          onPressed: () => presentQRScanner(context),
                          icon: const Icon(
                            Icons.qr_code,
                            color: DEuroColors.dEuroGold,
                          ),
                          label: S.of(context).scan,
                        ),
                      ),
                    Expanded(
                      child: VerticalIconButton(
                        onPressed: () => context.push("/send"),
                        icon: const Icon(
                          Icons.arrow_upward,
                          color: DEuroColors.dEuroGold,
                        ),
                        label: S.of(context).send,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

// Future<void> _presentQRReader(BuildContext context) async {
//   String result = await showDialog(
//     context: context,
//     builder: (dialogContext) => QRScanDialog(
//       validateQR: (code, _) =>
//           RegExp(r'(\b0x[a-fA-F0-9]{40}\b)').hasMatch(code!) ||
//           code.toLowerCase().startsWith("wc:") ||
//           OpenCryptoPayService.isOpenCryptoPayQR(code),
//       onData: (code, _) =>
//           Navigator.of(dialogContext, rootNavigator: true).pop(code),
//     ),
//   );
//
//   if (result.toLowerCase().startsWith("wc:")) {
//     getIt.get<WalletConnectService>().pairWithUri(Uri.parse(result));
//   } else if (OpenCryptoPayService.isOpenCryptoPayQR(result)) {
//     try {
//       final res = await getIt
//           .get<OpenCryptoPayService>()
//           .getOpenCryptoPayInvoice(result);
//       if (context.mounted) {
//         await Navigator.of(context)
//             .pushNamed(Routes.sendOpenCryptoPay, arguments: res);
//       }
//     } on OpenCryptoPayException catch (e) {
//       getIt.get<BottomSheetService>().queueBottomSheet(
//           isModalDismissible: true,
//           widget: BottomSheetMessageDisplayWidget(
//             message: e.message.toString(),
//           ));
//     }
//   } else if (result.startsWith("0x")) {
//     await Navigator.of(context)
//         .pushNamed(Routes.send, arguments: [result, null, null]);
//   } else {
//     final uri = ERC681URI.fromString(result);
//     await Navigator.of(context).pushNamed(Routes.send,
//         arguments: [uri.address, uri.amount, uri.asset]);
//   }
// }
}
