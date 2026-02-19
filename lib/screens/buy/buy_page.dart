import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_brokerbot_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/payment_info_error.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_buy_payment_info_service.dart';
import 'package:realunit_wallet/screens/buy/cubits/buy_converter/buy_converter_cubit.dart';
import 'package:realunit_wallet/screens/buy/cubits/buy_payment_info/buy_payment_info_cubit.dart';
import 'package:realunit_wallet/screens/buy/widgets/payment_converter.dart';
import 'package:realunit_wallet/screens/buy/widgets/payment_information.dart';
import 'package:realunit_wallet/screens/buy/legal_disclaimer_page.dart';
import 'package:realunit_wallet/styles/colors.dart';

class BuyPage extends StatelessWidget {
  static const routeName = '/buy';

  const BuyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => BuyConverterCubit(
            getIt<DfxBrokerbotService>(),
          )..onFiatChanged('1000'),
        ),
        BlocProvider(
          create: (_) => BuyPaymentInfoCubit(
            getIt<RealUnitBuyPaymentInfoService>(),
          )..getPaymentInfo(),
        ),
      ],
      child: const BuyView(),
    );
  }
}

class BuyView extends StatefulWidget {
  const BuyView({super.key});

  @override
  State<BuyView> createState() => _BuyViewState();
}

class _BuyViewState extends State<BuyView> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _resultController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          S.of(context).buyRealu,
        ),
      ),
      body: BlocConsumer<BuyConverterCubit, BuyConverterState>(
        listenWhen: (prev, next) => prev.loading && !next.loading,
        listener: (context, state) {
          _syncController(_amountController, state.fiatText);
          _syncController(_resultController, state.sharesText);
          context.read<BuyPaymentInfoCubit>().getPaymentInfo(amount: _amountController.text);
        },
        builder: (context, state) {
          return SafeArea(
            child: GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: LayoutBuilder(
                builder: (context, constraint) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraint.maxHeight),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PaymentConverter(
                                amountController: _amountController,
                                resultController: _resultController,
                              ),
                              const SizedBox(height: 32),
                              PaymentInformation(amount: _amountController.text),
                              const Spacer(),
                              BlocBuilder<BuyPaymentInfoCubit, BuyPaymentInfoState>(
                                builder: (context, paymentState) {
                                  if (paymentState is BuyPaymentInfoFailure &&
                                      paymentState.error == PaymentInfoError.registrationRequired) {
                                    final amount =
                                        double.tryParse(
                                          _amountController.text.replaceAll(',', '.'),
                                        ) ??
                                        0;
                                    final isValid = amount >= 1000;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 20),
                                      child: Column(
                                        spacing: 8,
                                        children: [
                                          if (!isValid)
                                            Text(
                                              S.of(context).buyMinAmount,
                                              style: const TextStyle(
                                                color: RealUnitColors.neutral500,
                                                fontSize: 14,
                                              ),
                                            ),
                                          SizedBox(
                                            width: double.infinity,
                                            child: FilledButton(
                                              onPressed: isValid
                                                  ? () async {
                                                      await context.push(LegalDisclaimerPage.routeName);
                                                      if (context.mounted) {
                                                        context
                                                            .read<BuyPaymentInfoCubit>()
                                                            .getPaymentInfo();
                                                      }
                                                    }
                                                  : null,
                                              child: Text(S.of(context).next),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  void _syncController(TextEditingController controller, String newValue) {
    if (controller.text == newValue) return;

    controller.value = controller.value.copyWith(
      text: newValue,
      selection: TextSelection.collapsed(offset: newValue.length),
      composing: TextRange.empty,
    );
  }
}
