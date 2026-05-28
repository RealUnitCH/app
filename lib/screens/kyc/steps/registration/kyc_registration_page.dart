import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_country_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_status.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_user_type.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/exceptions/signing_cancelled_exception.dart';
import 'package:realunit_wallet/screens/hardware_connect_bitbox/connect_bitbox_page.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/kyc/cubits/kyc/kyc_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/cubits/registration_step/kyc_registration_step_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/cubits/registration_submit/kyc_registration_submit_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/steps/kyc_registration_address_step.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/steps/kyc_registration_personal_step.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/styles/colors.dart';

class KycRegistrationPage extends StatelessWidget {
  const KycRegistrationPage({super.key});

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
      child: const KycRegistrationView(),
    );
  }
}

class KycRegistrationView extends StatefulWidget {
  const KycRegistrationView({super.key});

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

  bool _prefillLoading = true;
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
    unawaited(_prefillFromBackend());
  }

  // Pulls already-known personal data from the API so the form starts pre-filled instead of
  // forcing the user to retype values that must match the backend record byte-for-byte.
  // Any failure degrades gracefully to a blank form — same UX as before the fetch.
  Future<void> _prefillFromBackend() async {
    try {
      final walletStatus = await getIt<RealUnitWalletService>().getWalletStatus();
      final dto = walletStatus.realUnitUserDataDto;
      if (dto == null) {
        if (mounted) setState(() => _prefillLoading = false);
        return;
      }

      final countryService = getIt<DfxCountryService>();
      final countries = await Future.wait([
        countryService.getCountryBySymbol(dto.nationality),
        countryService.getCountryBySymbol(dto.addressCountry),
      ]);

      if (!mounted) return;
      setState(() {
        typeCtrl.value = RegistrationUserType.fromName(dto.type);
        firstnameCtrl.text = dto.kycData.firstName;
        lastnameCtrl.text = dto.kycData.lastName;
        phoneCtrl.value = dto.phoneNumber;
        birthdayCtrl.value = dto.birthday;
        nationalityCtrl.value = countries[0];
        _initialNationality = countries[0];
        addressStreetCtrl.text = dto.kycData.address.street;
        addressStreetNumberCtrl.text = dto.kycData.address.houseNumber ?? '';
        postalCodeCtrl.text = dto.kycData.address.zip;
        cityCtrl.text = dto.kycData.address.city;
        countryCtrl.value = countries[1];
        _initialAddressCountry = countries[1];
        _prefillLoading = false;
      });
    } catch (e) {
      developer.log('Failed to prefill RealUnit registration form: $e');
      if (mounted) setState(() => _prefillLoading = false);
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
            // so re-fetching `getWalletStatus` in `_runCheckKyc` will return
            // `AlreadyRegistered` and dispatch the next KYC step.
            context.read<KycCubit>().checkKyc();

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
            final message = state.cause is SigningCancelledException
                ? S.of(context).signingCancelled
                : S.of(context).registrationFailed(state.message);
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
              child: _prefillLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : Stack(
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
          onSubmit: _onSubmit,
        );
    }
  }

  Future<void> _onSubmit() async => await context.read<KycRegistrationSubmitCubit>().submit(
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
    swissTaxResidence: true,
  );

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
    super.dispose();
  }
}
