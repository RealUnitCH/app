import 'package:flutter/material.dart';
import 'package:realunit_wallet/generated/i18n.dart';

class RegistrationEmailVerificationStep extends StatelessWidget {
  const RegistrationEmailVerificationStep({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SafeArea(
          child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Column(
          children: [
            Text('Bestätige deine Mail'),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    // if (_formKey.currentState?.validate() ?? false) {
                    //   context.read<RegistrationEmailStepCubit>().checkEmail(emailCtrl.text);
                    // }
                  },
                  child: Text(S.of(context).next),
                ),
              ),
            ),
          ],
        ),
      )),
    );
  }
}
