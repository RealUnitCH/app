import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/bank_account.dart';
import 'package:realunit_wallet/screens/sell/cubits/sell_bank_accounts/sell_bank_accounts_cubit.dart';
import 'package:realunit_wallet/screens/sell/cubits/sell_selected_bank_account/sell_selected_bank_account_cubit.dart';
import 'package:realunit_wallet/screens/sell/widgets/sell_add_bank_account_sheet.dart';
import 'package:realunit_wallet/screens/sell/widgets/sell_bank_account_selection_page.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SellBankAccountField extends StatelessWidget {
  const SellBankAccountField({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => SellBankAccountsCubit(
            getIt<SharedPreferences>(),
          ),
        ),
      ],
      child: const BankAccountFieldView(),
    );
  }
}

class BankAccountFieldView extends StatelessWidget {
  const BankAccountFieldView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SellBankAccountsCubit, List<BankAccount>>(
      listenWhen: (previous, current) => previous.length != current.length,
      listener: (context, state) {
        if (state.isNotEmpty) {
          context.read<SellSelectedBankAccountCubit>().selectBankAccount(state.last);
        }
      },
      builder: (context, accounts) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 4.0,
                ),
                child: Text(
                  S.of(context).bankAccount,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    height: 18 / 13,
                  ),
                ),
              ),
            ],
          ),
          BlocBuilder<SellSelectedBankAccountCubit, BankAccount?>(
            builder: (context, selected) {
              return GestureDetector(
                onTap: () => _onAddBankAccountPressed(context),
                child: DropdownButtonFormField<BankAccount>(
                  initialValue: selected,
                  onChanged: null,
                  items: accounts
                      .map(
                        (account) => DropdownMenuItem(
                          value: account,
                          child: Text(
                            account.iban,
                            style: const TextStyle(
                              fontSize: 14,
                              color: RealUnitColors.neutral900,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  isExpanded: true,
                  isDense: true,
                  borderRadius: BorderRadius.circular(8.0),
                  menuMaxHeight: MediaQuery.sizeOf(context).height * 0.4,
                  decoration: const InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      borderSide: BorderSide(color: RealUnitColors.neutral300),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10.0,
                    ),
                  ),
                  hint: Text(
                    '${S.of(context).pleaseSelect}...',
                    style: const TextStyle(
                      color: RealUnitColors.neutral400,
                    ),
                  ),
                  icon: const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.arrow_drop_down),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _onAddBankAccountPressed(BuildContext context) async {
    final sellBankAccountsCubit = context.read<SellBankAccountsCubit>();
    final sellSelectedBankAccountCubit = context.read<SellSelectedBankAccountCubit>();

    if (sellBankAccountsCubit.state.isEmpty) {
      await showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (_) => BlocProvider.value(
          value: sellBankAccountsCubit,
          child: const SellAddBankAccountSheet(),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider.value(
                value: sellBankAccountsCubit,
              ),
              BlocProvider.value(
                value: sellSelectedBankAccountCubit,
              ),
            ],
            child: const SellBankAccountSelectionPage(),
          ),
        ),
      );
    }
  }
}
