import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/bank_account.dart';
import 'package:realunit_wallet/screens/sell/cubits/sell_bank_accounts/sell_bank_accounts_cubit.dart';
import 'package:realunit_wallet/styles/colors.dart';

class SellAddBankAccountSheet extends StatelessWidget {
  SellAddBankAccountSheet({super.key});

  final _ibanController = TextEditingController();
  final _nameController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.87,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            //Handlebars.horizontal(context, margin: EdgeInsets.only(top: 5), width: 36),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
              child: AppBar(
                title: Text(
                  'Auszahlungskonto hinzufügen',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 12.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  spacing: 16,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: Text(
                            'IBAN',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              height: 18 / 13,
                            ),
                          ),
                        ),
                        TextFormField(
                          controller: _ibanController,
                          // initialValue: initialValue,
                          // onChanged: onChanged,
                          autocorrect: false,
                          enableSuggestions: false,
                          textInputAction: TextInputAction.next,
                          // textCapitalization: textCapitalization,
                          decoration: InputDecoration(
                            hintText: 'CHXX XXXX XXXX XXXX XXXX X',
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8.0)),
                              borderSide: BorderSide(color: RealUnitColors.neutral300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8.0)),
                              borderSide: BorderSide(color: RealUnitColors.realUnitBlue, width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8.0)),
                              borderSide: BorderSide(color: RealUnitColors.status.red600),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8.0)),
                              borderSide: BorderSide(color: RealUnitColors.status.red600, width: 2),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                            hintStyle: TextStyle(color: RealUnitColors.neutral400),
                          ),
                          // keyboardType: keyboardType,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'IBAN erforderlich';
                            return null;
                          },
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: Text(
                            'Bezeichnung (optional)',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              height: 18 / 13,
                            ),
                          ),
                        ),
                        TextFormField(
                          controller: _nameController,
                          // initialValue: initialValue,
                          // onChanged: onChanged,
                          autocorrect: false,
                          enableSuggestions: false,
                          textInputAction: TextInputAction.next,
                          // textCapitalization: textCapitalization,
                          decoration: InputDecoration(
                            // hintText: hintText,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8.0)),
                              borderSide: BorderSide(color: RealUnitColors.neutral300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8.0)),
                              borderSide: BorderSide(color: RealUnitColors.realUnitBlue, width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8.0)),
                              borderSide: BorderSide(color: RealUnitColors.status.red600),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8.0)),
                              borderSide: BorderSide(color: RealUnitColors.status.red600, width: 2),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                            hintStyle: TextStyle(color: RealUnitColors.neutral400),
                          ),
                          // keyboardType: keyboardType,
                        ),
                      ],
                    ),
                    FilledButton(
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          final newBankAccount = BankAccount(
                            iban: _ibanController.text,
                            name: _nameController.text.isNotEmpty ? _nameController.text : null,
                          );

                          context.read<SellBankAccountsCubit>().addBankAccount(
                                bankAccount: newBankAccount,
                              );
                          context.pop(newBankAccount);
                        }
                      },
                      child: Text(S.of(context).next),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
