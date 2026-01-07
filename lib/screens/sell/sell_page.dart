import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_brokerbot_service.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_sell_payment_info_service.dart';
import 'package:realunit_wallet/screens/sell/cubits/sell_converter/sell_converter_cubit.dart';
import 'package:realunit_wallet/screens/sell/cubits/sell_payment_info/sell_payment_info_cubit.dart';
import 'package:realunit_wallet/screens/sell/cubits/sell_selected_bank_account/sell_selected_bank_account_cubit.dart';
import 'package:realunit_wallet/screens/sell/widgets/bank_account_field.dart';
import 'package:realunit_wallet/screens/sell/widgets/sell_converter.dart';

class SellPage extends StatelessWidget {
  static const routeName = '/sell';

  const SellPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => SellConverterCubit(
            getIt<DfxBrokerbotService>(),
          )..onSharesChanged('1000'),
        ),
        BlocProvider(
          create: (context) => SellPaymentInfoCubit(
            getIt<RealUnitSellPaymentInfoService>(),
          ),
        ),
        BlocProvider(
          create: (context) => SellSelectedBankAccountCubit(),
        ),
      ],
      child: SellView(),
    );
  }
}

class SellView extends StatelessWidget {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _resultController = TextEditingController();

  SellView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          S.of(context).sell_realu,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: BlocListener<SellConverterCubit, SellConverterState>(
        listenWhen: (prev, next) => prev.loading && !next.loading,
        listener: (context, state) {
          _syncController(_amountController, state.sharesText);
          _syncController(_resultController, state.fiatText);
        },
        child: SingleChildScrollView(
          child: SafeArea(
            child: GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  spacing: 32,
                  children: [
                    SellConverter(
                      amountController: _amountController,
                      resultController: _resultController,
                    ),
                    BankAccountField(),
                    FilledButton(
                      onPressed: () => context.read<SellPaymentInfoCubit>().getPaymentInfo(
                          amount: _amountController.text,
                          iban: context.read<SellSelectedBankAccountCubit>().state!.iban),
                      child: Text('${_amountController.text} REALU verkaufen'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
