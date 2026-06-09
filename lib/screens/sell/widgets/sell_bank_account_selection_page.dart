import 'dart:developer' as developer;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/sell/cubits/sell_bank_accounts/sell_bank_accounts_cubit.dart';
import 'package:realunit_wallet/screens/sell/cubits/sell_selected_bank_account/sell_selected_bank_account_cubit.dart';
import 'package:realunit_wallet/screens/sell/widgets/sell_add_bank_account_sheet.dart';
import 'package:realunit_wallet/screens/sell/widgets/sell_bank_account_list_item.dart';
import 'package:realunit_wallet/widgets/buttons/app_text_button.dart';

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
                          // Mirrors the auto-selection in `BankAccountFieldView`:
                          // API is authority — only the backend-tagged default
                          // (and only if active) is auto-selected. No active-
                          // fallback heuristic, otherwise re-opening this page
                          // would overwrite a correctly chosen default with the
                          // last-active account.
                          final defaults = state.accounts.where((a) => a.isDefault).toList();
                          if (defaults.length > 1) {
                            developer.log(
                              'Backend returned ${defaults.length} default '
                              'bank accounts; expected at most one. Picking '
                              'the first in list order.',
                              name: 'SellBankAccountSelectionPage',
                              level: 900,
                            );
                          }
                          context.read<SellSelectedBankAccountCubit>().selectBankAccount(
                            state.accounts.firstWhereOrNull(
                              (account) => account.isDefault && account.isActive,
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
                          final account = state.accounts.elementAt(index);
                          return SellBankAccountListItem(
                            account: account,
                            onTap: () {
                              context.read<SellSelectedBankAccountCubit>().selectBankAccount(
                                account,
                              );
                              context.pop();
                            },
                            onDelete: () async {
                              await context.read<SellBankAccountsCubit>().deactivate(
                                bankAccount: account,
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                AppTextButton(
                  onPressed: () => _onAddBankAccountPressed(context),
                  label: S.of(context).addBankAccount,
                  icon: Icons.add_circle_outlined,
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

    await showModalBottomSheet<void>(
      isScrollControlled: true,
      context: context,
      builder: (_) => BlocProvider.value(
        value: sellBankAccountsCubit,
        child: const SellAddBankAccountSheet(),
      ),
    );
  }
}
