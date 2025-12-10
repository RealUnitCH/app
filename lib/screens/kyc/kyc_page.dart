import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

  // STEP 1 controllers
  final emailCtrl = TextEditingController();
  final surnameCtrl = TextEditingController();
  final firstnameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  String birthday = "";

  // STEP 2 controllers
  final addressStreetCtrl = TextEditingController();
  final postalCodeCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final countryCtrl = TextEditingController();

  @override
  void dispose() {
    pageController.dispose();
    emailCtrl.dispose();
    firstnameCtrl.dispose();
    surnameCtrl.dispose();
    phoneCtrl.dispose();
    addressStreetCtrl.dispose();
    postalCodeCtrl.dispose();
    cityCtrl.dispose();
    countryCtrl.dispose();
    super.dispose();
  }

  void goNext() => pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );

  void goPrevious() => pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );

  void submitKyc() {
    final result = {
      "email": emailCtrl.text,
      "name": "${firstnameCtrl.text} ${surnameCtrl.text}",
      "phoneNumber": phoneCtrl.text,
      "birthday": birthday,
      "addressStreet": addressStreetCtrl.text,
      "addressPostalCode": postalCodeCtrl.text,
      "addressCity": cityCtrl.text,
      "addressCountry": countryCtrl.text,
      "type": "HUMAN",
      "lang": "EN",
    };

    debugPrint("KYC SUBMIT => $result");
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
                  emailCtrl: emailCtrl,
                  firstnameCtrl: firstnameCtrl,
                  surnameCtrl: surnameCtrl,
                  phoneCtrl: phoneCtrl,
                  onBirthdaySelected: (val) => birthday = val,
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
}
