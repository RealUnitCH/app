import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_registration_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/dfx_country.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/dfx_registration.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/dfx_user_type.dart';
import 'package:realunit_wallet/screens/kyc/steps/kyc_address_step.dart';
import 'package:realunit_wallet/screens/kyc/steps/kyc_personal_step.dart';
import 'package:realunit_wallet/styles/colors.dart';

class KycPage extends StatelessWidget {
  static const routeName = '/kyc';
  const KycPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const KycView();
  }
}

class KycView extends StatefulWidget {
  const KycView({super.key});

  @override
  State<KycView> createState() => _KycViewState();
}

class _KycViewState extends State<KycView> {
  final dfxService = getIt<DfxRegistrationService>();
  final pageController = PageController();

  int currentPage = 0;
  final int totalPages = 2;

  @override
  void initState() {
    super.initState();

    pageController.addListener(() {
      final newPage = pageController.page?.round() ?? 0;
      if (newPage != currentPage) {
        setState(() => currentPage = newPage);
      }
    });
  }

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

  void goNext() => pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );

  void goPrevious() => pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );

  Future<void> submitKyc() async {
    try {
      print('Sending registration request...');
      final response = await dfxService.register(
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
      );

      print('Registration successful! Response: ${response.toString()}');
      print(response.status);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: $e!'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: currentPage == 0 ? () => context.pop() : goPrevious,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          currentPage == 0 ? "Persönliche Daten" : "Residenz",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        spacing: 20.0,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: LinearProgressIndicator(
              value: (currentPage) / totalPages,
              backgroundColor: RealUnitColors.neutral200,
              valueColor: AlwaysStoppedAnimation<Color>(RealUnitColors.green),
            ),
          ),
          Expanded(
            child: PageView(
              controller: pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                KycPersonalStep(
                  typeCtrl: typeCtrl,
                  emailCtrl: emailCtrl,
                  firstNameCtrl: firstnameCtrl,
                  lastNameCtrl: lastnameCtrl,
                  nationalityCtrl: nationalityCtrl,
                  phoneCtrl: phoneCtrl,
                  birthdayCtrl: birthdayCtrl,
                  onNext: goNext,
                ),
                KycAddressStep(
                  addressStreetCtrl: addressStreetCtrl,
                  postalCodeCtrl: postalCodeCtrl,
                  cityCtrl: cityCtrl,
                  countryCtrl: countryCtrl,
                  onPrevious: goPrevious,
                  onSubmit: submitKyc,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    pageController.dispose();
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
