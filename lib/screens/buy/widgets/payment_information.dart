import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/buy/cubits/buy_bank_details/buy_bank_details_cubit.dart';
import 'package:realunit_wallet/screens/buy/widgets/payment_executed_sheet.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/styles.dart';

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
          return Center(
            child: Text(
              '${S.of(context).buy_payment_information_loading} ...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }

        if (state.bankDetails == null) {
          return Center(
            child: Text(
              S.of(context).buy_payment_information_not_available,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }

        final bankDetails = state.bankDetails!;
        final parsedAddress = _ParsedAddress.parse(bankDetails.address);
        return Column(
          children: [
            Text(
              S.of(context).buy_payment_information,
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
                    S.of(context).buy_payment_information_description,
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
            Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: BoxBorder.all(
                      width: 1,
                      color: RealUnitColors.neutral200,
                    ),
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Column(
                    children: _withDividers(
                      children: [
                        _PaymentInformationDetailsRow(
                          description: '${S.of(context).amount_in} ${bankDetails.currency}',
                          value: _amount,
                        ),
                        _PaymentInformationDetailsRow(
                          description: S.of(context).iban,
                          value: bankDetails.iban,
                        ),
                        _PaymentInformationDetailsRow(
                          description: S.of(context).bic,
                          value: bankDetails.bic,
                        ),
                        _PaymentInformationDetailsRow(
                          title: S.of(context).receiver,
                          description: S.of(context).name,
                          value: bankDetails.recipient,
                        ),
                        _PaymentInformationDetailsRow(
                          description: S.of(context).address,
                          value: parsedAddress.address,
                        ),
                        _PaymentInformationDetailsRow(
                          description: S.of(context).postcode_abr,
                          value: parsedAddress.plz,
                        ),
                        _PaymentInformationDetailsRow(
                          description: S.of(context).location,
                          value: parsedAddress.city,
                        ),
                        _PaymentInformationDetailsRow(
                          description: S.of(context).country,
                          value: parsedAddress.country,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
                    if (context.mounted) context.pop();
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
                    S.of(context).buy_payment_confirm,
                    textAlign: TextAlign.center,
                    style: kFullwidthBlueButtonTextStyle,
                  ),
                ),
              ),
            ),
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

class _ParsedAddress {
  final String address;
  final String plz;
  final String city;
  final String country;

  _ParsedAddress({
    required this.address,
    required this.plz,
    required this.city,
    required this.country,
  });

  /// temporary solution for splitting address until backend provides structured address data
  static _ParsedAddress parse(String input) {
    final parts = input.split(",").map((e) => e.trim()).toList();

    if (parts.length != 3) {
      throw FormatException("Unexpected address format: $input");
    }

    final address = parts[0];
    final plzCity = parts[1].split(" ");
    final country = parts[2];

    if (plzCity.length < 2) {
      throw FormatException("PLZ and city missing: ${parts[1]}");
    }

    final plz = plzCity.first;
    final city = plzCity.sublist(1).join(" ");

    return _ParsedAddress(
      address: address,
      plz: plz,
      city: city,
      country: country,
    );
  }
}
