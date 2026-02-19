import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/packages/service/dfx/models/country/country.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_status.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/registration_user_type.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';
import 'package:realunit_wallet/screens/kyc/cubits/kyc/kyc_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/cubits/registration_step/kyc_registration_step_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/cubits/registration_submit/kyc_registration_submit_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/steps/kyc_registration_address_step.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/steps/kyc_registration_email_step.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/steps/kyc_registration_personal_step.dart';
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

  final emailCtrl = TextEditingController();

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
        listener: (context, state) {
          if (state is KycRegistrationSubmitSuccess) {
            if (state.status == RegistrationStatus.completed) {
              context.read<KycCubit>().checkKyc();
            }
          }
          if (state is KycRegistrationSubmitFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Registration failed:\n${state.message}'),
                backgroundColor: RealUnitColors.status.red600,
              ),
            );
          }
        },
        child: Column(
          spacing: 20.0,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: BlocBuilder<KycRegistrationStepCubit, KycRegistrationStepState>(
                builder: (context, state) {
                  return LinearProgressIndicator(
                    value: state.progress,
                    backgroundColor: RealUnitColors.neutral200,
                    valueColor: const AlwaysStoppedAnimation<Color>(RealUnitColors.realUnitBlue),
                  );
                },
              ),
            ),
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
      case KycRegistrationStep.email:
        return KycRegistrationEmailStep(
          emailCtrl: emailCtrl,
          onSuccess: context.read<KycRegistrationStepCubit>().next,
        );

      case KycRegistrationStep.personal:
        return KycRegistrationPersonalStep(
          typeCtrl: typeCtrl,
          firstNameCtrl: firstnameCtrl,
          lastNameCtrl: lastnameCtrl,
          nationalityCtrl: nationalityCtrl,
          phoneCtrl: phoneCtrl,
          birthdayCtrl: birthdayCtrl,
        );

      case KycRegistrationStep.address:
        return KycRegistrationAddressStep(
          addressStreetCtrl: addressStreetCtrl,
          addressNumberCtrl: addressStreetNumberCtrl,
          postalCodeCtrl: postalCodeCtrl,
          cityCtrl: cityCtrl,
          countryCtrl: countryCtrl,
          onSubmit: _onSubmit,
        );
    }
  }

  Future<void> _onSubmit() async => await context.read<KycRegistrationSubmitCubit>().submit(
    Registration(
      type: typeCtrl.value,
      email: emailCtrl.text.trim().toLowerCase(),
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
    ),
  );

  @override
  void dispose() {
    _stepSubscription?.cancel();
    _pageController.dispose();
    typeCtrl.dispose();
    emailCtrl.dispose();
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
