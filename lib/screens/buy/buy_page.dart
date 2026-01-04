import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_allowlist_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_bank_details_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_brokerbot_service.dart';
import 'package:realunit_wallet/screens/buy/cubits/buy_allowlist/buy_allowlist_cubit.dart';
import 'package:realunit_wallet/screens/buy/cubits/buy_bank_details/buy_bank_details_cubit.dart';
import 'package:realunit_wallet/screens/buy/cubits/buy_converter/buy_converter_cubit.dart';
import 'package:realunit_wallet/screens/buy/widgets/payment_converter.dart';
import 'package:realunit_wallet/screens/buy/widgets/payment_information.dart';
import 'package:realunit_wallet/screens/buy/widgets/payment_not_possible_info.dart';
import 'package:realunit_wallet/screens/buy/widgets/payment_registration_required.dart';

class BuyPage extends StatelessWidget {
  static const routeName = '/buy';

  const BuyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => BuyAllowlistCubit(
            getIt<DfxAllowlistService>(),
          )..checkAddress(),
        ),
        BlocProvider(
          create: (_) => BuyConverterCubit(
            getIt<DfxBrokerbotService>(),
          )..onFiatChanged('300'),
        ),
        BlocProvider(
          create: (_) => BuyBankDetailsCubit(
            getIt<DfxBankDetailsService>(),
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
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _resultController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
                      BlocBuilder<BuyAllowlistCubit, BuyAllowlistState>(
                          builder: (context, allowlistState) {
                        if (allowlistState.loading) {
                          return const Center(
                            child: CupertinoActivityIndicator(),
                          );
                        }
                        if (!allowlistState.canReceive) {
                          return PaymentRegistrationRequired();
                        }
                        if (allowlistState.isForbidden) {
                          return PaymentNotPossibleInfo();
                        } else {
                          return PaymentInformation(
                            amount: _amountController.text,
                          );
                        }
                      })
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
