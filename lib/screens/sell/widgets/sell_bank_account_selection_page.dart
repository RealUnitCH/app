import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/bank_account.dart';
import 'package:realunit_wallet/screens/sell/cubits/sell_bank_accounts/sell_bank_accounts_cubit.dart';
import 'package:realunit_wallet/screens/sell/cubits/sell_selected_bank_account/sell_selected_bank_account_cubit.dart';
import 'package:realunit_wallet/screens/sell/widgets/sell_add_bank_account_sheet.dart';
import 'package:realunit_wallet/styles/colors.dart';

class SellBankAccountSelectionPage extends StatelessWidget {
  const SellBankAccountSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          S.of(context).payoutAccountSelect,
        ),
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              spacing: 16.0,
              children: [
                BlocConsumer<SellBankAccountsCubit, List<BankAccount>>(
                  listenWhen: (previous, current) => previous.length < current.length,
                  listener: (context, state) => context.pop(),
                  builder: (context, accounts) {
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: accounts.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16.0),
                      itemBuilder: (context, index) {
                        final account = accounts[index];
                        return GestureDetector(
                          onTap: () {
                            context.read<SellSelectedBankAccountCubit>().selectBankAccount(account);
                            Navigator.pop(context);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: RealUnitColors.brand200,
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  spacing: 4.0,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      account.name ??
                                          '${S.of(context).without} ${S.of(context).label}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        height: 16 / 12,
                                        letterSpacing: 0.0,
                                        color: RealUnitColors.neutral600,
                                      ),
                                    ),
                                    Text(
                                      account.iban,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        height: 18 / 14,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.0,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: RealUnitColors.neutral400,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  padding: const EdgeInsets.all(8.0),
                                  child: GestureDetector(
                                    onTap: () => context
                                        .read<SellBankAccountsCubit>()
                                        .remove(bankAccount: account),
                                    child: const Icon(
                                      Icons.delete_outline_outlined,
                                      color: RealUnitColors.realUnitBlack,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                TextButton.icon(
                  onPressed: () => _onAddBankAccountPressed(context),
                  label: Text(
                    S.of(context).addBankAccount,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 20 / 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.0,
                      color: RealUnitColors.realUnitBlue,
                    ),
                  ),
                  icon: const Icon(
                    Icons.add_circle_outlined,
                    color: RealUnitColors.realUnitBlue,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onAddBankAccountPressed(BuildContext context) async {
    final sellBankAccountsCubit = context.read<SellBankAccountsCubit>();

    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (_) => BlocProvider.value(
        value: sellBankAccountsCubit,
        child: const SellAddBankAccountSheet(),
      ),
    );
  }
}
