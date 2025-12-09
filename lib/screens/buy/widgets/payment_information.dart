import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/screens/buy/cubit/buy_bank_details/buy_bank_details_cubit.dart';
import 'package:realunit_wallet/screens/buy/cubit/buy_bank_details/buy_bank_details_state.dart';
import 'package:realunit_wallet/styles/colors.dart';

class PaymentInformation extends StatelessWidget {
  const PaymentInformation({
    super.key,
    required String amount,
  }) : _amount = amount;

  final String _amount;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BuyBankDetailsCubit, BuyBankDetailsState>(
      builder: (context, state) {
        if (state.loading) {
          Center(child: Text('Lade Zahlungsinformationen ...'));
        }
        if (state.bankDetails == null) {
          Center(child: Text('Keine Zahlungsinformationen verfügbar.'));
        }
        return Column(
          children: [
            Text(
              'Zahlungsinformationen',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6),
            Row(
              spacing: 12,
              children: [
                Icon(
                  Icons.info,
                  size: 16,
                  color: RealUnitColors.realUnitBlue,
                ),
                Expanded(
                  child: Text(
                    'Bitte überweise den Kaufbetrag mit diesen Angaben über deine Bankanwendung. Der Verwendungszweck ist wichtig!',
                    style: TextStyle(
                      fontSize: 14,
                      height: 18 / 14,
                      letterSpacing: 0.0,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            if (state.bankDetails != null) ...[
              Container(
                decoration: BoxDecoration(
                  border: BoxBorder.all(
                    width: 1,
                    color: RealUnitColors.neutral200,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  children: _withDividers(
                    children: [
                      _PaymentInformationDetailsRow(
                        description: 'Betrag in ${state.bankDetails!.currency}',
                        value: _amount,
                      ),
                      _PaymentInformationDetailsRow(
                        description: 'IBAN',
                        value: state.bankDetails!.iban,
                      ),
                      _PaymentInformationDetailsRow(
                        description: 'BIC',
                        value: state.bankDetails!.bic,
                      ),
                      _PaymentInformationDetailsRow(
                        description: 'Verwendungszweck',
                        value: 'REALU-723232',
                      ),
                      _PaymentInformationDetailsRow(
                        title: 'Empfänger',
                        description: 'Name',
                        value: state.bankDetails!.recipient,
                      ),
                      _PaymentInformationDetailsRow(
                        description: 'Adresse',
                        value: state.bankDetails!.address,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  List<Widget> _withDividers({required List<Widget> children}) {
    final result = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i < children.length - 1) {
        result.add(
          Divider(
            color: RealUnitColors.neutral200,
          ),
        );
      }
    }
    return result;
  }
}

class _PaymentInformationDetailsRow extends StatelessWidget {
  const _PaymentInformationDetailsRow({
    this.title,
    required this.description,
    required this.value,
  });

  final String? title;
  final String description;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20.0,
        vertical: 12.0,
      ),
      child: Column(
        spacing: 20.0,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Text(
              title!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                height: 18 / 14,
                letterSpacing: 0.0,
              ),
            ),
          Row(
            spacing: 12.0,
            children: [
              Text(
                description,
                style: TextStyle(
                  color: RealUnitColors.realUnitBlue,
                  fontSize: 14,
                  height: 18 / 14,
                  letterSpacing: 0.0,
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    height: 18 / 14,
                    letterSpacing: 0.0,
                  ),
                ),
              ),
              InkWell(
                child: Icon(
                  Icons.copy_outlined,
                  color: RealUnitColors.realUnitBlue,
                  fontWeight: FontWeight.bold,
                  size: 16,
                ),
                onTap: () => Clipboard.setData(
                  ClipboardData(
                    text: value,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
