import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_brokerbot_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/buy_payment_info_error.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_buy_payment_info_service.dart';
import 'package:realunit_wallet/screens/buy/cubits/buy_converter/buy_converter_cubit.dart';
import 'package:realunit_wallet/screens/buy/cubits/buy_payment_info/buy_payment_info_cubit.dart';
import 'package:realunit_wallet/screens/buy/widgets/payment_action_required.dart';
import 'package:realunit_wallet/screens/buy/widgets/payment_converter.dart';
import 'package:realunit_wallet/screens/buy/widgets/payment_information.dart';
import 'package:realunit_wallet/screens/registration/registration_page.dart';

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
          )..onFiatChanged('300'),
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
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          S.of(context).buy_realu,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: BlocConsumer<BuyConverterCubit, BuyConverterState>(
        listenWhen: (prev, next) =>
            prev.fiatText != next.fiatText || prev.sharesText != next.sharesText,
        listener: (context, state) {
          _syncController(_amountController, state.fiatText);
          _syncController(_resultController, state.sharesText);
        },
        builder: (context, state) {
          return SingleChildScrollView(
            child: SafeArea(
              child: GestureDetector(
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    spacing: 32,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PaymentConverter(
                        amountController: _amountController,
                        resultController: _resultController,
                      ),
                      BlocListener<BuyConverterCubit, BuyConverterState>(
                        listenWhen: (prev, next) => prev.fiatText != next.fiatText,
                        listener: (context, state) {
                          final amount = int.tryParse(state.fiatText);
                          if (amount != null) {
                            context.read<BuyPaymentInfoCubit>().getPaymentInfo(amount: amount);
                          }
                        },
                        child: BlocBuilder<BuyPaymentInfoCubit, BuyPaymentInfoState>(
                          builder: (context, paymentInfoState) {
                            if (paymentInfoState is BuyPaymentInfoSuccess) {
                              return PaymentInformation(
                                amount: _amountController.text,
                                buyPaymentInfo: paymentInfoState.buyPaymentInfo,
                              );
                            }
                            if (paymentInfoState is BuyPaymentInfoLoading) {
                              return const Center(
                                child: CupertinoActivityIndicator(),
                              );
                            }
                            if (paymentInfoState is BuyPaymentInfoFailure) {
                              final error = paymentInfoState.error;
                              if (error == BuyPaymentInfoError.registrationRequired) {
                                return PaymentActionRequired(
                                  title: 'Registrierung erforderlich',
                                  description: S.of(context).identity_check_description,
                                  onPressed: () async {
                                    await context.push(RegistrationPage.routeName);
                                    if (context.mounted) {
                                      context.read<BuyPaymentInfoCubit>().getPaymentInfo();
                                    }
                                  },
                                );
                              } else if (error == BuyPaymentInfoError.kycRequired) {
                                return PaymentActionRequired(
                                  title: S.of(context).identity_check_required,
                                  description:
                                      'Der Betrag liegt über Ihrem Limit. Um dieses zu erhöhen, bestätigen Sie bitte Ihre Identität (KYC) über DFX.',
                                  onPressed: () {},
                                );
                              }
                              return PaymentActionRequired(title: 'Unbekannter Fehler', description: 'Es ist ein unbekannter Fehler aufgetreten. Bitte melde dich beim Support.',)
                            }
                            return SizedBox.shrink();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
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
