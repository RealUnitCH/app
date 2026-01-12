import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/utils/format_fixed.dart';
import 'package:realunit_wallet/screens/send/bloc/gas_fee_cubit.dart';
import 'package:realunit_wallet/screens/send_invoice/bloc/expiry_cubit.dart';
import 'package:realunit_wallet/screens/send_invoice/bloc/send_invoice_bloc.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/styles.dart';
import 'package:realunit_wallet/widgets/amount_info_row.dart';
import 'package:realunit_wallet/widgets/blockchain_selector.dart';
import 'package:realunit_wallet/widgets/info_row.dart';

class SendInvoiceView extends StatelessWidget {
  const SendInvoiceView({super.key});

  static const _kPadding = EdgeInsets.only(left: 26, right: 26, bottom: 10);

  void _onCancel(BuildContext context) {
    context.read<SendInvoiceBloc>().add(const CancelInvoice());
    context.pop();
  }

  void _onConfirm(BuildContext context) {
    context.read<SendInvoiceBloc>().add(const SendSubmitted());
    context.pop();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: CupertinoNavigationBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            onPressed: () => _onCancel(context),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: RealUnitColors.realUnitBlack,
              size: 24,
            ),
          ),
          middle: const Text(
            "Open CryptoPay",
            style: kPageTitleTextStyle,
          ),
          border: null,
        ),
        body: SafeArea(
          child: BlocBuilder<SendInvoiceBloc, SendInvoiceState>(
            builder: (context, sendState) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 30, bottom: 20),
                  child: Text(
                    sendState.invoice.receiverName,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                Text(
                  "${sendState.invoice.amount} ${sendState.invoice.amountSymbol}",
                  style: const TextStyle(fontSize: 60),
                  textAlign: TextAlign.center,
                ),
                Text(
                  "${formatFixed(sendState.dEuroAmount, 18, fractionalDigits: 2)} dEuro",
                  style: const TextStyle(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                BlockchainSelector(
                  onPressed: (blockchain) =>
                      context.read<SendInvoiceBloc>().add(ChainChanged(blockchain)),
                  blockchain: sendState.blockchain,
                  padding: _kPadding,
                ),
                BlocBuilder<GasFeeCubit, GasFeeState>(
                  bloc: context.read<SendInvoiceBloc>().gasFeeCubit,
                  builder: (context, state) => AmountInfoRow(
                    padding: _kPadding,
                    title: S.of(context).fee,
                    amountString: state.formatedFee,
                    currencySymbol: sendState.blockchain.nativeSymbol,
                  ),
                ),
                BlocBuilder<ExpiryCubit, ExpiryState>(
                    bloc: context.read<SendInvoiceBloc>().expiryCubit,
                    builder: (context, state) {
                      final isActive = sendState.status == SendStatus.initial && !state.isExpired;

                      return Column(
                        children: [
                          InfoRow(
                            padding: _kPadding,
                            leading: S.of(context).expires_in,
                            trailing: S.of(context).expires_in_seconds("${state.secondsRemaining}"),
                          ),
                          Padding(
                            padding: _kPadding,
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: FilledButton(
                                        onPressed: isActive ? () => _onCancel(context) : null,
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          fixedSize: const Size(double.infinity, 55),
                                        ),
                                        child: const Icon(
                                          CupertinoIcons.xmark,
                                          color: Colors.white,
                                          size: 19,
                                        )),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: FilledButton(
                                    onPressed: isActive ? () => _onConfirm(context) : null,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      fixedSize: const Size(double.infinity, 55),
                                    ),
                                    child: sendState.status == SendStatus.inProgress
                                        ? const CupertinoActivityIndicator()
                                        : Text(
                                            S.of(context).pay,
                                            style: kPageTitleTextStyle,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
              ],
            ),
          ),
        ),
      );
}
