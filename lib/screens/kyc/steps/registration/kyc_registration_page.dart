import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_country_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/dto/real_unit_registration_request_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_status.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_user_type.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/dto/real_unit_user_data_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';
import 'package:realunit_wallet/packages/wallet/exceptions/signing_cancelled_exception.dart';
import 'package:realunit_wallet/screens/hardware_connect_bitbox/connect_bitbox_page.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/kyc/cubits/kyc/kyc_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/cubits/registration_step/kyc_registration_step_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/cubits/registration_submit/kyc_registration_submit_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/steps/kyc_registration_address_step.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/steps/kyc_registration_personal_step.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/steps/kyc_registration_tax_step.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/styles/colors.dart';

class KycRegistrationPage extends StatelessWidget {
  /// Server-supplied user data the parent `KycCubit` already fetched as part
  /// of its routing decision. Passed in via constructor so the page does not
  /// re-issue `getRegistrationInfo()` — there is one round-trip per decision.
  /// `null` for first-time registrations with no prior record on the backend
  /// (the form renders empty in that case).
  final RealUnitUserDataDto? initialUserData;

  const KycRegistrationPage({super.key, this.initialUserData});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => KycRegistrationSubmitCubit(
            getIt<RealUnitRegistrationService>(),
            getIt<DfxKycService>(),
          ),
        ),
        BlocProvider(
          create: (_) => KycRegistrationStepCubit(),
        ),
      ],
      child: KycRegistrationView(initialUserData: initialUserData),
    );
  }
}

class KycRegistrationView extends StatefulWidget {
  final RealUnitUserDataDto? initialUserData;

  const KycRegistrationView({super.key, this.initialUserData});

  @override
  State<KycRegistrationView> createState() => _KycRegistrationViewState();
}

class _KycRegistrationViewState extends State<KycRegistrationView> {
  final _pageController = PageController();
  StreamSubscription<KycRegistrationStepState>? _stepSubscription;

  final typeCtrl = ValueNotifier<RegistrationUserType>(RegistrationUserType.human);
  final lastnameCtrl = TextEditingController();
  final firstnameCtrl = TextEditingController();
  final phoneCtrl = ValueNotifier<String?>(null);
  final nationalityCtrl = ValueNotifier<Country?>(null);
  final birthdayCtrl = ValueNotifier<String?>(null);

  final addressStreetCtrl = TextEditingController();
  final addressStreetNumberCtrl = TextEditingController();
  final postalCodeCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final countryCtrl = ValueNotifier<Country?>(null);
  final taxCountryCtrl = ValueNotifier<Country?>(null);
  final tinCtrl = TextEditingController();

  Country? _initialNationality;
  Country? _initialAddressCountry;

  @override
  void initState() {
    super.initState();
    _stepSubscription = context.read<KycRegistrationStepCubit>().stream.listen((state) {
      _pageController.animateToPage(
        state.index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });

    // Seed the form synchronously from whatever the parent cubit handed in.
    // The non-country scalars are available immediately; the two country
    // lookups still need the country service (the DTO only carries 2-letter
    // symbols), but the form is rendered straight away — country fields just
    // populate when the lookup resolves. No loading gate, no re-fetch of the
    // wallet status.
    final dto = widget.initialUserData;
    if (dto != null) {
      typeCtrl.value = RegistrationUserType.fromName(dto.type);
      firstnameCtrl.text = dto.kycData.firstName;
      lastnameCtrl.text = dto.kycData.lastName;
      phoneCtrl.value = dto.phoneNumber;
      birthdayCtrl.value = dto.birthday;
      addressStreetCtrl.text = dto.kycData.address.street;
      addressStreetNumberCtrl.text = dto.kycData.address.houseNumber ?? '';
      postalCodeCtrl.text = dto.kycData.address.zip;
      cityCtrl.text = dto.kycData.address.city;
      unawaited(_resolveInitialCountries(dto.nationality, dto.addressCountry));
    }
  }

  Future<void> _resolveInitialCountries(
    String nationalitySymbol,
    String addressCountrySymbol,
  ) async {
    try {
      final countryService = getIt<DfxCountryService>();
      final countries = await Future.wait([
        countryService.getCountryBySymbol(nationalitySymbol),
        countryService.getCountryBySymbol(addressCountrySymbol),
      ]);
      if (!mounted) return;
      setState(() {
        nationalityCtrl.value = countries[0];
        _initialNationality = countries[0];
        countryCtrl.value = countries[1];
        _initialAddressCountry = countries[1];
      });
    } catch (_) {
      // Country lookup failed (unknown symbol or network error): degrade
      // gracefully to the empty country fields — the user can pick manually
      // and the form still submits.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: BlocBuilder<KycRegistrationStepCubit, KycRegistrationStepState>(
          builder: (context, state) {
            return AppBar(
              leading: IconButton(
                onPressed: state.canGoBack
                    ? context.read<KycRegistrationStepCubit>().previous
                    : context.pop,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              title: Text(
                state.title(context),
              ),
            );
          },
        ),
      ),
      body: BlocListener<KycRegistrationSubmitCubit, KycRegistrationSubmitState>(
        listener: (context, state) async {
          if (state is KycRegistrationSubmitSuccess) {
            // The submit cubit only emits Success after a successful EIP-712
            // sign through `_signEip712`, regardless of the resulting backend
            // status (completed, pendingReview, forwardingFailed,
            // alreadyRegistered). The backend now reflects the new wallet,
            // so re-fetching `getRegistrationInfo` in `_runCheckKyc` will return
            // `AlreadyRegistered` and dispatch the next KYC step.
            context.read<KycCubit>().checkKyc();

            // Account now exists on the backend: re-arm the wallet services so
            // the balance poll resumes (it stops itself after 404ing while the
            // account was missing — see BalanceService).
            context.read<HomeBloc>().add(SyncWalletServicesEvent(getIt<AppStore>().wallet));

            if (state.status == RegistrationStatus.forwardingFailed) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(S.of(context).registrationForwardingFailed),
                  backgroundColor: RealUnitColors.status.red600,
                ),
              );
            }
          }
          if (state is KycRegistrationSubmitFailure) {
            final cause = state.cause;
            final String message;
            if (cause is SigningCancelledException) {
              message = S.of(context).signingCancelled;
            } else if (cause is ApiException &&
                cause.statusCode != null &&
                cause.statusCode! >= 400 &&
                cause.statusCode! < 500) {
              // A structured 4xx is a rejection of THIS submit — surface the
              // server reason with the "nothing was saved" context so it is
              // not mistaken for a hang (the wizard state is purely local and
              // a rejected submit persists nothing). 5xx/auth/transport
              // errors stay on the generic message: "check your entries"
              // would be the wrong instruction there.
              message = S.of(context).registrationRejected(cause.message);
            } else {
              message = S.of(context).registrationFailed(state.message);
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: RealUnitColors.status.red600,
              ),
            );
          }
          if (state is KycRegistrationSubmitBitboxRequired) {
            final registration = state.registration;
            final result = await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => ConnectBitboxPage(
                onFinish: (wallet) {
                  context.read<HomeBloc>().add(SyncWalletServicesEvent(wallet));
                  context.pop(true);
                },
              ),
            );
            if (context.mounted && result == true) {
              context.read<KycRegistrationSubmitCubit>().retrySubmit(registration);
            }
          }
        },
        child: Column(
          spacing: 20.0,
          children: [
            Expanded(
              child: Stack(
                children: [
                  PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: KycRegistrationStep.values.map(_buildStep).toList(),
                  ),
                  BlocBuilder<KycRegistrationSubmitCubit, KycRegistrationSubmitState>(
                    builder: (context, state) {
                      if (state is KycRegistrationSubmitLoading) {
                        return Container(
                          color: RealUnitColors.basic.white,
                          child: const Center(
                            child: CupertinoActivityIndicator(),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(KycRegistrationStep step) {
    switch (step) {
      case KycRegistrationStep.personal:
        return KycRegistrationPersonalStep(
          typeCtrl: typeCtrl,
          firstNameCtrl: firstnameCtrl,
          lastNameCtrl: lastnameCtrl,
          nationalityCtrl: nationalityCtrl,
          phoneCtrl: phoneCtrl,
          birthdayCtrl: birthdayCtrl,
          initialNationality: _initialNationality,
        );

      case KycRegistrationStep.address:
        return KycRegistrationAddressStep(
          addressStreetCtrl: addressStreetCtrl,
          addressNumberCtrl: addressStreetNumberCtrl,
          postalCodeCtrl: postalCodeCtrl,
          cityCtrl: cityCtrl,
          countryCtrl: countryCtrl,
          initialCountry: _initialAddressCountry,
        );

      case KycRegistrationStep.taxResidence:
        // Default the tax-residence country to the residence country entered on
        // the address step, rebuilding when it changes — most people are
        // tax-resident where they live. The field stays editable; CountryField
        // propagates the default into `taxCountryCtrl` and reveals the TIN for a
        // non-Swiss default.
        return ValueListenableBuilder<Country?>(
          valueListenable: countryCtrl,
          builder: (context, residenceCountry, _) => KycRegistrationTaxStep(
            taxCountryCtrl: taxCountryCtrl,
            tinCtrl: tinCtrl,
            initialCountry: residenceCountry,
            onSubmit: _onSubmit,
          ),
        );
    }
  }

  Future<void> _onSubmit() async {
    // `swissTaxResidence` is derived from the tax-residence country picked on
    // the final step: a Swiss (CH) tax residence is Swiss-only, and the TIN is
    // forwarded only for a non-Swiss tax residence (matching the backend
    // contract).
    final swissTaxResidence = taxCountryCtrl.value!.symbol == 'CH';
    final countryAndTINs = swissTaxResidence
        ? null
        : [
            CountryAndTin(
              country: taxCountryCtrl.value!.symbol,
              tin: tinCtrl.text.trim(),
            ),
          ];
    await context.read<KycRegistrationSubmitCubit>().submit(
      type: typeCtrl.value,
      firstName: firstnameCtrl.text.trim(),
      lastName: lastnameCtrl.text.trim(),
      phoneNumber: phoneCtrl.value?.trim() ?? '',
      birthday: birthdayCtrl.value ?? '',
      nationality: nationalityCtrl.value!,
      addressStreet: addressStreetCtrl.text.trim(),
      addressStreetNumber: addressStreetNumberCtrl.text.trim(),
      addressPostalCode: postalCodeCtrl.text.trim(),
      addressCity: cityCtrl.text.trim(),
      addressCountry: countryCtrl.value!,
      swissTaxResidence: swissTaxResidence,
      countryAndTINs: countryAndTINs,
    );
  }

  @override
  void dispose() {
    _stepSubscription?.cancel();
    _pageController.dispose();
    typeCtrl.dispose();
    firstnameCtrl.dispose();
    lastnameCtrl.dispose();
    phoneCtrl.dispose();
    nationalityCtrl.dispose();
    addressStreetCtrl.dispose();
    addressStreetNumberCtrl.dispose();
    postalCodeCtrl.dispose();
    cityCtrl.dispose();
    countryCtrl.dispose();
    taxCountryCtrl.dispose();
    tinCtrl.dispose();
    super.dispose();
  }
}
