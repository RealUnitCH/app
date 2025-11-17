import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/models/blockchain.dart';
import 'package:realunit_wallet/packages/service/transaction_history_service.dart';
import 'package:realunit_wallet/packages/utils/get_blockexplorer.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/styles.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class TransactionSentPage extends StatelessWidget {
  final String transactionId;
  final Blockchain blockchain;
  final String title;

  const TransactionSentPage({
    super.key,
    required this.title,
    required this.transactionId,
    required this.blockchain,
  });

  static const _kPadding = EdgeInsets.only(left: 26, right: 26, bottom: 60);

  void _onOpenExplorerPressed() {
    final baseURl = getBlockExplorerUrl(blockchain);
    final uri = Uri.parse("$baseURl/tx/$transactionId");
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      backgroundColor: RealUnitColors.realUnitBlue,
                      radius: 32,
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 46,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(
                        title,
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                    InkWell(
                      onTap: _onOpenExplorerPressed,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            transactionId.asShortTxId,
                            style: TextStyle(
                              color: DEuroColors.neutralGrey,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 10),
                            child: Icon(
                              Icons.open_in_new,
                              size: 18,
                              color: DEuroColors.neutralGrey,
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: _kPadding,
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => context.pop(),
                    style: kFullwidthGrayButtonStyle,
                    child: Text(
                      S.of(context).done,
                      textAlign: TextAlign.center,
                      style: kTitleTextStyle,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      );
}
