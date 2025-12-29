import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_registration_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/dfx_country.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/dfx_registration.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/dfx_user_type.dart';
import 'package:realunit_wallet/screens/registration/cubits/registration_step/registration_step_cubit.dart';
import 'package:realunit_wallet/screens/registration/cubits/registration_submit/registration_submit_cubit.dart';
import 'package:realunit_wallet/screens/registration/steps/registration_address_step.dart';
import 'package:realunit_wallet/screens/registration/steps/registration_completed_step.dart';
import 'package:realunit_wallet/screens/registration/steps/registration_personal_step.dart';
import 'package:realunit_wallet/styles/colors.dart';

class RegistrationPage extends StatelessWidget {
  static const routeName = '/register';
  const RegistrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => RegistrationSubmitCubit(
            getIt<DfxRegistrationService>(),
          ),
        ),
        BlocProvider(
          create: (_) => RegistrationStepCubit(),
        ),
      ],
      child: const RegisterView(),
    );
  }
}

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final dfxService = getIt<DfxRegistrationService>();
  final _pageController = PageController();

  final typeCtrl = ValueNotifier<DfxUserType>(DfxUserType.human);
  final emailCtrl = TextEditingController();
  final lastnameCtrl = TextEditingController();
  final firstnameCtrl = TextEditingController();
  final phoneCtrl = ValueNotifier<String?>(null);
  final nationalityCtrl = ValueNotifier<DfxCountry?>(null);
  final birthdayCtrl = ValueNotifier<String?>(null);

  final addressStreetCtrl = TextEditingController();
  final postalCodeCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final countryCtrl = ValueNotifier<DfxCountry?>(null);

  @override
  void initState() {
    context.read<RegistrationStepCubit>().stream.listen((state) {
      _pageController.animateToPage(
        state.index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: BlocBuilder<RegistrationStepCubit, RegistrationStepState>(
          builder: (context, state) {
            return AppBar(
              leading: IconButton(
                onPressed: state.canGoBack
                    ? context.read<RegistrationStepCubit>().previous
                    : () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              title: Text(
                state.title,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            );
          },
        ),
      ),
      body: BlocListener<RegistrationSubmitCubit, RegistrationSubmitState>(
        listener: (context, state) {
          if (state == RegistrationSubmitState.successful) {
            context.read<RegistrationStepCubit>().next();
          }
          if (state == RegistrationSubmitState.failed) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Registration failed!'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Column(
          spacing: 20.0,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: BlocBuilder<RegistrationStepCubit, RegistrationStepState>(
                builder: (context, state) {
                  return LinearProgressIndicator(
                    value: state.progress,
                    backgroundColor: RealUnitColors.neutral200,
                    valueColor: AlwaysStoppedAnimation<Color>(RealUnitColors.green),
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
                    children: [
                      RegistrationPersonalStep(
                        typeCtrl: typeCtrl,
                        emailCtrl: emailCtrl,
                        firstNameCtrl: firstnameCtrl,
                        lastNameCtrl: lastnameCtrl,
                        nationalityCtrl: nationalityCtrl,
                        phoneCtrl: phoneCtrl,
                        birthdayCtrl: birthdayCtrl,
                        onNext: context.read<RegistrationStepCubit>().next,
                      ),
                      RegisterAddressStep(
                        addressStreetCtrl: addressStreetCtrl,
                        postalCodeCtrl: postalCodeCtrl,
                        cityCtrl: cityCtrl,
                        countryCtrl: countryCtrl,
                        onPrevious: context.read<RegistrationStepCubit>().previous,
                        onSubmit: () => context.read<RegistrationSubmitCubit>().submit(
                              DfxRegistration(
                                type: typeCtrl.value,
                                email: emailCtrl.text,
                                firstName: firstnameCtrl.text,
                                lastName: lastnameCtrl.text,
                                phoneNumber: phoneCtrl.value ?? '',
                                birthday: birthdayCtrl.value ?? '',
                                nationality: nationalityCtrl.value!,
                                addressStreet: addressStreetCtrl.text,
                                addressPostalCode: postalCodeCtrl.text,
                                addressCity: cityCtrl.text,
                                addressCountry: countryCtrl.value!,
                                swissTaxResidence: true,
                                registrationDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                              ),
                            ),
                      ),
                      RegistrationCompletedStep(),
                    ],
                  ),
                  BlocBuilder<RegistrationSubmitCubit, RegistrationSubmitState>(
                    builder: (context, state) {
                      if (state == RegistrationSubmitState.loading) {
                        return Container(
                          color: RealUnitColors.basic.white,
                          child: const Center(
                            child: CircularProgressIndicator(),
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

  @override
  void dispose() {
    _pageController.dispose();
    typeCtrl.dispose();
    emailCtrl.dispose();
    firstnameCtrl.dispose();
    lastnameCtrl.dispose();
    phoneCtrl.dispose();
    nationalityCtrl.dispose();
    addressStreetCtrl.dispose();
    postalCodeCtrl.dispose();
    cityCtrl.dispose();
    countryCtrl.dispose();
    super.dispose();
  }
}
