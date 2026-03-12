import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/kyc/cubits/kyc/kyc_cubit.dart';
import 'package:realunit_wallet/styles/colors.dart';

class KycAccountMergePage extends StatelessWidget {
  const KycAccountMergePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).kyc),
      ),
      body: Padding(
        padding: const .symmetric(horizontal: 20.0),
        child: SafeArea(
          child: Column(
            spacing: 8.0,
            children: [
              const Spacer(),
              Text(
                S.of(context).kycAccountMergeTitle,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: .center,
              ),
              Text(
                S.of(context).kycAccountMergeDescription,
                textAlign: .center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: RealUnitColors.neutral500,
                ),
              ),
              Padding(
                padding: const .symmetric(vertical: 16.0),
                child: SizedBox(
                  width: .infinity,
                  child: FilledButton(
                    onPressed: () => context.read<KycCubit>().checkKyc(),
                    child: Text(S.of(context).refresh),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
