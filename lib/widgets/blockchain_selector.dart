import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/models/blockchain.dart';
import 'package:realunit_wallet/packages/utils/asset_logo.dart';
import 'package:realunit_wallet/styles/styles.dart';
import 'package:realunit_wallet/widgets/handlebars.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BlockchainSelector extends StatelessWidget {
  const BlockchainSelector({
    super.key,
    required this.onPressed,
    this.blockchain = Blockchain.ethereum,
    this.padding,
  });

  final Blockchain blockchain;
  final void Function(Blockchain blockchain) onPressed;
  final EdgeInsetsGeometry? padding;

  Future<void> _openSelector(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.only(top: 5, bottom: 16),
            child: Handlebars.horizontal(context),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  S.of(context).select_network,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              ...Blockchain.values.map(
                (blockchain) => Padding(
                  padding: const EdgeInsets.all(2.5),
                  child: GestureDetector(
                    onTap: () {
                      onPressed.call(blockchain);
                      context.pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Image.asset(
                              getChainImagePath(blockchain.chainId),
                              width: 40,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  blockchain.name,
                                  style: kPageTitleTextStyle,
                                ),
                              ],
                            ),
                          ),
                          if (blockchain == this.blockchain) Icon(Icons.check)
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding ?? const EdgeInsets.only(top: 5, bottom: 5),
        child: Row(
          children: [
            Expanded(
              child: Text(
                "${S.of(context).blockchain}:",
                style: kPageTitleTextStyle,
              ),
            ),
            GestureDetector(
              onTap: () => _openSelector(context),
              child: Padding(
                padding: const EdgeInsets.only(top: 7, bottom: 7, left: 7),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: CircleAvatar(
                        radius: 12,
                        backgroundImage:
                            AssetImage(getChainImagePath(blockchain.chainId)),
                      ),
                    ),
                    Text(
                      blockchain.name,
                      style: kPageTitleTextStyle,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}
