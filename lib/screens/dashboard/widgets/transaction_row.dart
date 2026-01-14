import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/models/transaction.dart';
import 'package:realunit_wallet/packages/service/transaction_history_service.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/icons.dart';
import 'package:realunit_wallet/widgets/chain_asset_icon.dart';
import 'package:realunit_wallet/widgets/hide_amount_text.dart';

class TransactionRow extends StatelessWidget {
  final Transaction transaction;
  final String walletAddress;
  final Color backgroundColor;
  final Color firstRowTextColor;
  final Color secondRowTextColor;
  final bool showBlockchainIcon;
  final bool navigateToDetails;

  const TransactionRow({
    super.key,
    required this.transaction,
    required this.walletAddress,
    this.backgroundColor = Colors.white,
    this.firstRowTextColor = RealUnitColors.realUnitBlack,
    this.secondRowTextColor = DEuroColors.titanGray60,
    this.showBlockchainIcon = false,
    this.navigateToDetails = true,
  });

  bool get isOutbound => transaction.isOutbound(walletAddress);

  TextStyle get _firstRowTextStyle =>
      TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: firstRowTextColor);

  TextStyle get _secondRowTextStyle => TextStyle(fontSize: 12, color: secondRowTextColor);

  @override
  Widget build(BuildContext context) =>
      [TransactionTypes.savingsAdd, TransactionTypes.savingsRemove].contains(transaction.type)
          ? SavingsTransactionRow(
              transaction: transaction,
              backgroundColor: backgroundColor,
              firstRowTextColor: firstRowTextColor,
              secondRowTextColor: secondRowTextColor,
              showBlockchainIcon: showBlockchainIcon,
              navigateToDetails: navigateToDetails,
            )
          : InkWell(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: backgroundColor,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ChainAssetIcon(asset: transaction.asset),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Text(
                                    transaction.asset.name,
                                    style: _firstRowTextStyle,
                                  ),
                                  const Spacer(),
                                  HideAmountText(
                                    leadingSymbol: isOutbound ? '-' : '',
                                    amount: transaction.amount,
                                    decimals: transaction.asset.decimals,
                                    fractionalDigits: 0,
                                    trimZeros: false,
                                    trailingSymbol: transaction.asset.symbol,
                                    style: _firstRowTextStyle,
                                  )
                                ]),
                                Row(children: [
                                  Text(
                                    '${isOutbound ? S.of(context).to : S.of(context).from} ${isOutbound ? transaction.receiverAddress.asShortAddress : transaction.senderAddress.asShortAddress}',
                                    style: _secondRowTextStyle,
                                  ),
                                  const Spacer(),
                                  Text(
                                    DateFormat('MMM dd, yyyy').format(transaction.timestamp),
                                    style: _secondRowTextStyle,
                                  )
                                ]),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
}

class SavingsTransactionRow extends StatelessWidget {
  final Transaction transaction;
  final Color backgroundColor;
  final Color firstRowTextColor;
  final Color secondRowTextColor;
  final bool showBlockchainIcon;
  final bool navigateToDetails;

  const SavingsTransactionRow({
    super.key,
    required this.transaction,
    this.backgroundColor = Colors.white,
    this.firstRowTextColor = RealUnitColors.realUnitBlack,
    this.secondRowTextColor = DEuroColors.titanGray60,
    this.showBlockchainIcon = false,
    this.navigateToDetails = true,
  });

  TextStyle get _firstRowTextStyle =>
      TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: firstRowTextColor);

  TextStyle get _secondRowTextStyle => TextStyle(fontSize: 12, color: secondRowTextColor);

  @override
  Widget build(BuildContext context) => InkWell(
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: backgroundColor,
          ),
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (transaction.type == TransactionTypes.savingsRemove)
                    const CollectInterestIcon(size: 24),
                  if (transaction.type == TransactionTypes.savingsAdd)
                    const Icon(Icons.savings, size: 24),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(
                              transaction.type == TransactionTypes.savingsAdd
                                  ? S.of(context).savingsAdd
                                  : S.of(context).savingsRemove,
                              style: _firstRowTextStyle,
                            ),
                            const Spacer(),
                            HideAmountText(
                              leadingSymbol: '',
                              amount: transaction.amount,
                              decimals: transaction.asset.decimals,
                              fractionalDigits: 2,
                              trimZeros: false,
                              trailingSymbol: transaction.asset.symbol,
                              style: _firstRowTextStyle,
                            )
                          ]),
                          Row(children: [
                            Text(
                              DateFormat('MMM dd, yyyy').format(transaction.timestamp),
                              style: _secondRowTextStyle,
                            )
                          ]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}
