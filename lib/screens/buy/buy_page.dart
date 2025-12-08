import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_allowlist_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/dfx_brokerbot_service.dart';
import 'package:realunit_wallet/screens/buy/cubit/buy_allowlist/buy_allowlist_cubit.dart';
import 'package:realunit_wallet/screens/buy/cubit/buy_price/buy_price_cubit.dart';
import 'package:realunit_wallet/screens/buy/cubit/buy_price/buy_price_state.dart';
import 'package:realunit_wallet/styles/colors.dart';

class BuyPage extends StatelessWidget {
  static const routeName = '/buy';

  const BuyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => BuyAllowlistCubit(
            DfxAllowlistService(getIt<AppStore>())
              ..checkAllowlist(
                getIt<AppStore>().primaryAddress,
              ),
          ),
        ),
        BlocProvider(
          create: (_) => BuyCubit(
            DfxBrokerbotService(getIt<AppStore>()),
          ),
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
    context.read<BuyCubit>().onChfChanged(_amountController.text);
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
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocConsumer<BuyCubit, BuyState>(
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
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 4.0,
                  ),
                  child: Text(
                    'Du bezahlst',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: RealUnitColors.neutral400),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10.0,
                              vertical: 14.0,
                            ),
                          ),
                          maxLines: 1,
                          onChanged: (value) {
                            context.read<BuyCubit>().onChfChanged(value);
                          },
                        ),
                      ),
                      Container(
                        color: RealUnitColors.neutral400,
                        width: 2,
                        height: 50,
                        margin: const EdgeInsets.symmetric(horizontal: 10.0),
                      ),
                      const Expanded(
                        flex: 2,
                        child: Text(
                          "CHF",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 4.0,
                  ),
                  child: Text(
                    'Du erhältst',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: RealUnitColors.neutral400),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _resultController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: false,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly, // only allow 0-9
                          ],
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 14.0),
                          ),
                          maxLines: 1,
                          onChanged: (value) {
                            context.read<BuyCubit>().onSharesChanged(value);
                          },
                        ),
                      ),
                      Container(
                        color: RealUnitColors.neutral400,
                        width: 2,
                        height: 50,
                        margin: const EdgeInsets.symmetric(horizontal: 10.0),
                      ),
                      const Expanded(
                        flex: 2,
                        child: Text(
                          "REALU",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
