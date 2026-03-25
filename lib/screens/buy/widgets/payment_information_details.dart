import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/buy/buy_payment_info.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_buy_payment_info_service.dart';
import 'package:realunit_wallet/packages/utils/svg_parser.dart';
import 'package:realunit_wallet/screens/buy/cubits/buy_confirm/buy_confirm_cubit.dart';
import 'package:realunit_wallet/screens/buy/widgets/payment_executed_sheet.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/styles.dart';
import 'package:realunit_wallet/widgets/tab_selector.dart';

enum PaymentInfoOptions {
  text,
  qrCode,
}

class PaymentInformationDetails extends StatelessWidget {
  final String amount;
  final BuyPaymentInfo buyPaymentInfo;

  const PaymentInformationDetails({
    super.key,
    required this.buyPaymentInfo,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BuyConfirmCubit(
        getIt<RealUnitBuyPaymentInfoService>(),
      ),
      child: PaymentInformationDetailsView(
        buyPaymentInfo: buyPaymentInfo,
        amount: amount,
      ),
    );
  }
}

class PaymentInformationDetailsView extends StatelessWidget {
  final String amount;
  final BuyPaymentInfo buyPaymentInfo;

  const PaymentInformationDetailsView({
    super.key,
    required this.buyPaymentInfo,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final selectedTab = ValueNotifier(PaymentInfoOptions.text);
    final hasQrCode = buyPaymentInfo.paymentRequest != null;

    return BlocListener<BuyConfirmCubit, BuyConfirmState>(
      listener: (context, state) async {
        if (state is BuyConfirmSuccess) {
          await showModalBottomSheet(
            context: context,
            builder: (_) => PaymentExecutedSheet(reference: state.reference),
          );
          if (context.mounted) context.pop();
        }
        if (state is BuyConfirmFailure) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(S.of(context).buyPaymentConfirmFailed),
              ),
            );
          }
        }
      },
      child: ValueListenableBuilder<PaymentInfoOptions>(
        valueListenable: selectedTab,
        builder: (context, tabIndex, _) {
          return Column(
            spacing: 16.0,
            children: [
              Column(
                spacing: 6.0,
                children: [
                  Text(
                    S.of(context).buyPaymentInformation,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: .bold),
                  ),
                  Row(
                    spacing: 12,
                    children: [
                      const Icon(
                        Icons.info,
                        size: 24,
                        color: RealUnitColors.realUnitBlue,
                      ),
                      Expanded(
                        child: Text(
                          S.of(context).buyPaymentInformationDescription,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                spacing: 12,
                children: [
                  if (hasQrCode)
                    TabSelector<PaymentInfoOptions>(
                      tabs: PaymentInfoOptions.values,
                      selectedTab: selectedTab.value,
                      onTabSelected: (index) => selectedTab.value = index,
                      labelBuilder: (context, tab, isSelected) {
                        return Text(
                          switch (tab) {
                            PaymentInfoOptions.text => S.of(context).details,
                            PaymentInfoOptions.qrCode => S.of(context).qrCode,
                          },
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: isSelected ? .w600 : .normal,
                            color: isSelected
                                ? RealUnitColors.realUnitBlue
                                : RealUnitColors.neutral500,
                          ),
                        );
                      },
                    ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 1,
                        color: RealUnitColors.neutral200,
                      ),
                      borderRadius: .circular(16.0),
                    ),
                    child: switch (tabIndex) {
                      PaymentInfoOptions.text => Column(
                        mainAxisSize: .min,
                        children: _withDividers(
                          children: [
                            _PaymentInformationDetailsRow(
                              description:
                                  '${S.of(context).amountIn} ${buyPaymentInfo.currency.code}',
                              value: amount,
                            ),
                            if (buyPaymentInfo.remittanceInfo != null)
                              _PaymentInformationDetailsRow(
                                description: S.of(context).purposeOfPayment,
                                value: buyPaymentInfo.remittanceInfo!,
                              ),
                            _PaymentInformationDetailsRow(
                              description: S.of(context).iban,
                              value: buyPaymentInfo.iban,
                            ),
                            _PaymentInformationDetailsRow(
                              description: S.of(context).bic,
                              value: buyPaymentInfo.bic,
                            ),
                            _PaymentInformationDetailsRow(
                              title: S.of(context).receiver,
                              description: S.of(context).name,
                              value: buyPaymentInfo.name,
                            ),
                            _PaymentInformationDetailsRow(
                              description: S.of(context).address,
                              value: '${buyPaymentInfo.street} ${buyPaymentInfo.number}',
                            ),
                            _PaymentInformationDetailsRow(
                              description: S.of(context).postcodeAbr,
                              value: buyPaymentInfo.zip,
                            ),
                            _PaymentInformationDetailsRow(
                              description: S.of(context).location,
                              value: buyPaymentInfo.city,
                            ),
                            _PaymentInformationDetailsRow(
                              description: S.of(context).country,
                              value: buyPaymentInfo.country,
                            ),
                          ],
                        ),
                      ),
                      PaymentInfoOptions.qrCode => Container(
                        padding: const .all(16.0),
                        child: Center(
                          child: SvgPicture.string(
                            SvgParser.normalize(buyPaymentInfo.paymentRequest!),
                            width: MediaQuery.widthOf(context) * 0.6,
                            fit: .contain,
                          ),
                        ),
                      ),
                    },
                  ),
                ],
              ),
              Padding(
                padding: const .symmetric(vertical: 20),
                child: SizedBox(
                  width: .infinity,
                  child: BlocBuilder<BuyConfirmCubit, BuyConfirmState>(
                    builder: (context, state) {
                      return state is BuyConfirmLoading
                          ? FilledButton.icon(
                              onPressed: null,
                              icon: SizedBox(
                                height: 14,
                                width: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: RealUnitColors.basic.black.withValues(alpha: 0.5),
                                ),
                              ),
                              label: const SizedBox.shrink(),
                            )
                          : FilledButton(
                              onPressed: () => context.read<BuyConfirmCubit>().confirmPayment(
                                buyPaymentInfo.id,
                              ),
                              style: ButtonStyle(
                                padding: WidgetStateProperty.resolveWith(
                                  (states) => const .symmetric(
                                    vertical: 10.0,
                                    horizontal: 20.0,
                                  ),
                                ),
                              ),
                              child: Text(
                                S.of(context).buyPaymentConfirm,
                                textAlign: .center,
                                style: kFullwidthBlueButtonTextStyle,
                              ),
                            );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _withDividers({required List<Widget> children}) {
    final result = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i < children.length - 1) {
        result.add(
          const Divider(
            color: RealUnitColors.neutral200,
          ),
        );
      }
    }
    return result;
  }
}

class _PaymentInformationDetailsRow extends StatelessWidget {
  const _PaymentInformationDetailsRow({
    this.title,
    required this.description,
    required this.value,
  });

  final String? title;
  final String description;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20.0,
        vertical: 12.0,
      ),
      child: Column(
        spacing: 20.0,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Text(
              title!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                height: 18 / 14,
                letterSpacing: 0.0,
              ),
            ),
          Row(
            spacing: 12.0,
            children: [
              Text(
                description,
                style: const TextStyle(
                  color: RealUnitColors.realUnitBlue,
                  fontSize: 14,
                  height: 18 / 14,
                  letterSpacing: 0.0,
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    height: 18 / 14,
                    letterSpacing: 0.0,
                  ),
                ),
              ),
              InkWell(
                child: const Icon(
                  Icons.copy_outlined,
                  color: RealUnitColors.realUnitBlue,
                  fontWeight: FontWeight.bold,
                  size: 16,
                ),
                onTap: () => Clipboard.setData(
                  ClipboardData(
                    text: value,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
