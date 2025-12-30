import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/dfx_registration_status.dart';
import 'package:realunit_wallet/screens/registration/cubits/registration_submit/registration_submit_cubit.dart';

class RegistrationCompletedStep extends StatelessWidget {
  const RegistrationCompletedStep({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.read<RegistrationSubmitCubit>().state;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SafeArea(
        child: Column(
          spacing: 24,
          children: [
            Spacer(),
            Text(
              'Verifikation abgeschlossen',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 26,
                letterSpacing: 26 * -0.02,
                height: 30 / 26,
              ),
            ),
            if (state is RegistrationSubmitSuccess)
              Text(
                state.status == DfxRegistrationStatus.completed
                    ? 'Sie können nun mit dem Kauf losgehen.'
                    : 'Wir werden die Daten zu prüfen. Das kann bis zu einem Werktag dauern.',
                style: TextStyle(
                  fontSize: 14,
                  height: 18 / 14,
                  letterSpacing: 0.0,
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: context.pop,
                  child: Text(S.of(context).close),
                ),
              ),
            ),
            Spacer(),
          ],
        ),
      ),
    );
  }
}
