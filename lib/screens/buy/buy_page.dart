import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_allowlist_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_bank_details_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_brokerbot_service.dart';
import 'package:realunit_wallet/screens/buy/cubit/buy_allowlist/buy_allowlist_cubit.dart';
import 'package:realunit_wallet/screens/buy/cubit/buy_bank_details/buy_bank_details_cubit.dart';
import 'package:realunit_wallet/screens/buy/cubit/buy_converter/buy_converter_cubit.dart';
import 'package:realunit_wallet/screens/buy/cubit/buy_converter/buy_converter_state.dart';
import 'package:realunit_wallet/screens/buy/widgets/payment_converter.dart';
import 'package:realunit_wallet/screens/buy/widgets/payment_executed_sheet.dart';
import 'package:realunit_wallet/screens/buy/widgets/payment_information.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/styles.dart';

class BuyPage extends StatelessWidget {
  static const routeName = '/buy';

  const BuyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => BuyAllowlistCubit(
            DfxAllowlistService(
              getIt<AppStore>(),
            ),
          )..checkAddress(),
        ),
        BlocProvider(
          create: (_) => BuyConverterCubit(
            DfxBrokerbotService(
              getIt<AppStore>(),
            ),
          ),
        ),
        BlocProvider(
          create: (_) => BuyBankDetailsCubit(
            DfxBankDetailsService(
              getIt<AppStore>(),
            ),
          )..fetchBankDetails(),
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
  final TextEditingController _amountController = TextEditingController(text: '1.00');
  final TextEditingController _resultController = TextEditingController();

  @override
  void initState() {
    context.read<BuyConverterCubit>().onChfChanged(_amountController.text);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'REALU kaufen',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: BlocConsumer<BuyConverterCubit, BuyConverterState>(
        listenWhen: (prev, next) =>
            prev.chfText != next.chfText || prev.sharesText != next.sharesText,
        listener: (context, state) {
          if (_amountController.text != state.chfText) {
            _amountController.text = state.chfText;
          }
          if (_resultController.text != state.sharesText) {
            _resultController.text = state.sharesText;
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PaymentConverter(
                    amountController: _amountController,
                    resultController: _resultController,
                  ),
                  SizedBox(
                    height: 32,
                  ),
                  PaymentInformation(
                    amount: _amountController.text,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () async {
                          await showModalBottomSheet(
                            context: context,
                            builder: (context) => PaymentExecutedSheet(),
                          );
                        },
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(
                            RealUnitColors.realUnitBlue,
                          ),
                          padding: WidgetStateProperty.all(
                            const EdgeInsets.symmetric(
                              vertical: 10.0,
                              horizontal: 20.0,
                            ),
                          ),
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(60.0),
                            ),
                          ),
                        ),
                        child: Text(
                          'Klicken Sie hier, sobald Sie die Überweisung getätigt haben',
                          textAlign: TextAlign.center,
                          style: kFullwidthBlueButtonTextStyle,
                        ),
                      ),
                    ),
                  ),
                ],
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
}
