import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/screens/kyc/steps/address_change/cubit/kyc_address_change_cubit.dart';
import 'package:realunit_wallet/screens/kyc/widgets/fields/kyc_country_field.dart';
import 'package:realunit_wallet/screens/kyc/widgets/kyc_text_field.dart';

class KycAddressChangePage extends StatelessWidget {
  final String url;

  const KycAddressChangePage({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => KycAddressChangeCubit(kycService: getIt<DfxKycService>()),
      child: KycAddressChangeView(url: url),
    );
  }
}

class KycAddressChangeView extends StatefulWidget {
  final String url;

  const KycAddressChangeView({super.key, required this.url});

  @override
  State<KycAddressChangeView> createState() => _KycAddressChangeViewState();
}

class _KycAddressChangeViewState extends State<KycAddressChangeView> {
  final _formKey = GlobalKey<FormState>();
  final _streetCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _postalCodeCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _countryCtrl = ValueNotifier<Country?>(null);

  @override
  void dispose() {
    _streetCtrl.dispose();
    _numberCtrl.dispose();
    _postalCodeCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).changeAddress)),
      body: BlocConsumer<KycAddressChangeCubit, KycAddressChangeState>(
        listener: (context, state) {
          if (state is KycAddressChangeSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(S.of(context).changeSuccess)),
            );
            context.pop();
          }
        },
        builder: (context, state) {
          if (state is KycAddressChangeLoading) {
            return const Center(child: CupertinoActivityIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: SafeArea(
              child: GestureDetector(
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                behavior: HitTestBehavior.opaque,
                child: Form(
                  key: _formKey,
                  child: Column(
                    spacing: 16,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 10,
                        children: [
                          Expanded(
                            flex: 2,
                            child: KycTextField(
                              hintText: 'Musterstrasse',
                              controller: _streetCtrl,
                              label: S.of(context).street,
                              keyboardType: TextInputType.streetAddress,
                              textCapitalization: TextCapitalization.words,
                              validator: (value) {
                                if (value == null || value.isEmpty) return '';
                                return null;
                              },
                            ),
                          ),
                          Expanded(
                            child: KycTextField(
                              hintText: '13',
                              controller: _numberCtrl,
                              label: S.of(context).houseNumber,
                              keyboardType: TextInputType.streetAddress,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 10,
                        children: [
                          Expanded(
                            flex: 2,
                            child: KycTextField(
                              hintText: '8000',
                              controller: _postalCodeCtrl,
                              label: S.of(context).postcodeAbr,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) return '';
                                return null;
                              },
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: KycTextField(
                              hintText: 'Zurich',
                              controller: _cityCtrl,
                              label: S.of(context).city,
                              keyboardType: TextInputType.text,
                              textCapitalization: TextCapitalization.words,
                              validator: (value) {
                                if (value == null || value.isEmpty) return '';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      KycCountryField(
                        label: S.of(context).country,
                        onChanged: (country) => _countryCtrl.value = country,
                        validator: (value) {
                          if (value == null) return '';
                          return null;
                        },
                      ),
                      if (state is KycAddressChangeFailure)
                        Text(
                          state.message,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () {
                              FocusManager.instance.primaryFocus?.unfocus();
                              if (_formKey.currentState?.validate() ?? false) {
                                final country = _countryCtrl.value;
                                if (country != null) {
                                  context.read<KycAddressChangeCubit>().submitAddress(
                                        widget.url,
                                        street: _streetCtrl.text,
                                        houseNumber: _numberCtrl.text,
                                        zip: _postalCodeCtrl.text,
                                        city: _cityCtrl.text,
                                        country: country.symbol,
                                      );
                                }
                              }
                            },
                            child: Text(S.of(context).save),
                          ),
                        ),
                      ),
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
}
