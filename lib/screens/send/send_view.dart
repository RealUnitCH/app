import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/transaction_history_service.dart';
import 'package:realunit_wallet/packages/wallet/is_evm_address.dart';
import 'package:realunit_wallet/screens/send/bloc/gas_fee_cubit.dart';
import 'package:realunit_wallet/screens/send/bloc/send_bloc.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/styles.dart';
import 'package:realunit_wallet/widgets/amount_info_row.dart';
import 'package:realunit_wallet/widgets/asset_selector.dart';
import 'package:realunit_wallet/widgets/number_pad.dart';
import 'package:realunit_wallet/widgets/standard_slide_button_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SendView extends StatelessWidget {
  SendView({super.key, String? receiver})
      : receiverController = TextEditingController(text: receiver),
        receiverFocusNode = FocusNode();

  static const _kPadding = EdgeInsets.only(left: 26, right: 26, bottom: 10);

  final TextEditingController receiverController;
  final FocusNode receiverFocusNode;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: DEuroColors.anthracite,
              size: 24,
            ),
          ),
        ),
        body: SafeArea(
          child: BlocListener<SendBloc, SendState>(
            listener: (context, state) {
              if (state.receiver.isEthereumAddress) receiverFocusNode.unfocus();
              if (receiverController.text != state.receiver) {
                receiverController.text = state.receiver;
              }
            },
            listenWhen: (previous, current) =>
                !previous.receiver.isEthereumAddress &&
                current.receiver.isEthereumAddress,
            child: BlocBuilder<SendBloc, SendState>(
              builder: (context, sendState) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 26, right: 26, top: 26, bottom: 10),
                    child: TextField(
                      controller: receiverController,
                      focusNode: receiverFocusNode,
                      onChanged: (receiver) => context
                          .read<SendBloc>()
                          .add(ReceiverChanged(receiver)),
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.deny(RegExp(r" ")),
                      ],
                      decoration: InputDecoration(
                        hintText: S.of(context).receiver,
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: RealUnitColors.realUnitBlue),
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: RealUnitColors.realUnitBlue),
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                      ),
                    ),
                  ),
                  if (sendState.alias != null &&
                      !sendState.receiver.isEthereumAddress) ...[
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 26, right: 26, top: 10),
                      child: InkWell(
                        onTap: () {
                          receiverFocusNode.unfocus();
                          context.read<SendBloc>().add(SelectAlias());
                        },
                        child: Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: CircleAvatar(child: Icon(Icons.person)),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sendState.alias!.name,
                                  style: kTitleTextStyle,
                                ),
                                Text(
                                  sendState.alias!.address.asMediumAddress,
                                  style: kSubtitleTextStyle,
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (sendState.receiver.isEthereumAddress &&
                      !receiverFocusNode.hasFocus) ...[
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 26, right: 26, top: 10),
                      child: Text(
                        "${sendState.amount.toString()} €",
                        style: const TextStyle(fontSize: 60),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Spacer(),
                    AssetSelector(
                      onPressed: (asset) =>
                          context.read<SendBloc>().add(AssetChanged(asset)),
                      selectedBalance: sendState.balances.firstWhere(
                          (e) => e.chainId == sendState.blockchain.chainId),
                      availableBalances: sendState.balances,
                      padding: _kPadding,
                    ),
                    BlocBuilder<GasFeeCubit, GasFeeState>(
                      bloc: context.read<SendBloc>().gasFeeCubit,
                      builder: (context, state) => AmountInfoRow(
                        padding: _kPadding,
                        title: S.of(context).fee,
                        amountString: state.formatedFee,
                        currencySymbol: sendState.blockchain.nativeSymbol,
                      ),
                    ),
                    NumberPad(
                      onNumberPressed: (index) =>
                          context.read<SendBloc>().add(AmountChangedAdd(index)),
                      onDeletePressed: () =>
                          context.read<SendBloc>().add(AmountChangedDelete()),
                      onDecimalPressed: () =>
                          context.read<SendBloc>().add(AmountChangedDecimal()),
                    ),
                    Padding(
                      padding: _kPadding,
                      child: sendState.status == SendStatus.inProgress
                          ? SizedBox(
                              height: 55,
                              child: CupertinoActivityIndicator(
                                color: DEuroColors.dEuroGold,
                              ),
                            )
                          : StandardSlideButton(
                              onSlideComplete: () =>
                                  context.read<SendBloc>().add(SendSubmitted()),
                              buttonText: S.of(context).send,
                            ),
                    )
                  ],
                ],
              ),
            ),
          ),
        ),
      );
}
