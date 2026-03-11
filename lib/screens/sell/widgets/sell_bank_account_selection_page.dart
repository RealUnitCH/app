import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
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
            padding: const .symmetric(horizontal: 20.0),
            child: Column(
              spacing: 16.0,
              children: [
                MultiBlocListener(
                  listeners: [
                    BlocListener<SellBankAccountsCubit, SellBankAccountsState>(
                      listener: (context, state) {
                        if (state is SellBankAccountsSuccess) {
                          context.read<SellSelectedBankAccountCubit>().selectBankAccount(
                            state.accounts.lastWhereOrNull(
                              (account) => account.isActive,
                            ),
                          );
                        }
                      },
                    ),
                    BlocListener<SellBankAccountsCubit, SellBankAccountsState>(
                      listenWhen: (previous, current) =>
                          previous.accounts.length < current.accounts.length,
                      listener: (context, state) => context.pop(),
                    ),
                  ],
                  child: BlocBuilder<SellBankAccountsCubit, SellBankAccountsState>(
                    builder: (context, state) {
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.accounts.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16.0),
                        itemBuilder: (context, index) {
                          final account = state.accounts[index];
                          if (account.isActive) {
                            return GestureDetector(
                              onTap: () {
                                context.read<SellSelectedBankAccountCubit>().selectBankAccount(
                                  account,
                                );
                                Navigator.pop(context);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: RealUnitColors.brand200,
                                  borderRadius: .circular(12.0),
                                ),
                                padding: const .symmetric(
                                  horizontal: 12.0,
                                  vertical: 8.0,
                                ),
                                child: Row(
                                  mainAxisAlignment: .spaceBetween,
                                  children: [
                                    Column(
                                      spacing: 4.0,
                                      crossAxisAlignment: .start,
                                      children: [
                                        Text(
                                          account.name ??
                                              '${S.of(context).without} ${S.of(context).label}',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: RealUnitColors.neutral600,
                                          ),
                                        ),
                                        Text(
                                          account.iban,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontWeight: .w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        border: .all(
                                          color: RealUnitColors.neutral400,
                                        ),
                                        borderRadius: .circular(8.0),
                                      ),
                                      padding: const .all(8.0),
                                      child: GestureDetector(
                                        onTap: () async {
                                          await context.read<SellBankAccountsCubit>().deactivate(
                                            bankAccount: account,
                                          );
                                        },
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
                          } else {
                            return Container(
                              decoration: BoxDecoration(
                                color: RealUnitColors.neutral300,
                                borderRadius: .circular(12.0),
                              ),
                              padding: const .symmetric(
                                horizontal: 12.0,
                                vertical: 10.0,
                              ),
                              child: Column(
                                spacing: 4.0,
                                crossAxisAlignment: .start,
                                children: [
                                  Text(
                                    'deaktiviert',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: RealUnitColors.neutral500,
                                    ),
                                  ),
                                  Text(
                                    account.iban,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: .w600,
                                      color: RealUnitColors.realUnitBlack.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _onAddBankAccountPressed(context),
                  label: Text(
                    S.of(context).addBankAccount,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: .bold,
                      color: RealUnitColors.realUnitBlue,
                    ),
                  ),
                  icon: const Icon(
                    Icons.add_circle_outlined,
                    color: RealUnitColors.realUnitBlue,
                  ),
                ),
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
