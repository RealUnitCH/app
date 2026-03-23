import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/verify_seed/cubit/verify_seed_cubit.dart';
import 'package:realunit_wallet/styles/colors.dart';

class VerifySeedButton extends StatelessWidget {
  const VerifySeedButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const .symmetric(vertical: 20),
      child: SizedBox(
        width: .infinity,
        child: _buildButton(context),
      ),
    );
  }

  Widget _buildButton(BuildContext context) {
    final state = context.watch<VerifySeedCubit>().state;

    if (state.hasError) {
      return FilledButton(
        onPressed: null,
        style: ButtonStyle(
          backgroundColor: .resolveWith((states) => RealUnitColors.status.red600),
          foregroundColor: .resolveWith((states) => RealUnitColors.basic.white),
        ),
        child: Text(
          S.of(context).verifySeedInvalid,
          textAlign: .center,
        ),
      );
    }
    if (state.isVerified) {
      return FilledButton.icon(
        onPressed: null,
        icon: Icon(Icons.check, color: RealUnitColors.basic.white),
        style: ButtonStyle(
          backgroundColor: .resolveWith((states) => RealUnitColors.green),
          foregroundColor: .resolveWith((states) => RealUnitColors.basic.white),
        ),
        label: Text(
          S.of(context).verifySeedSuccessful,
          textAlign: .center,
        ),
      );
    }
    return FilledButton(
      onPressed: state.canVerify ? () => context.read<VerifySeedCubit>().verify() : null,
      child: Text(
        S.of(context).confirm,
      ),
    );
  }
}
