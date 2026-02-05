import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/kyc/cubits/kyc/kyc_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/ident/cubits/kyc_ident/kyc_ident_cubit.dart';
import 'package:realunit_wallet/styles/colors.dart';

class KycIdentPage extends StatelessWidget {
  final String accessToken;

  const KycIdentPage({super.key, required this.accessToken});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => KycIdentCubit(),
      child: KycIdentView(accessToken: accessToken),
    );
  }
}

class KycIdentView extends StatelessWidget {
  final String accessToken;

  const KycIdentView({super.key, required this.accessToken});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ident')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: BlocListener<KycIdentCubit, KycIdentState>(
          listener: (context, state) {
            if (state is KycIdentSuccess) {
              context.read<KycCubit>().checkKyc();
            }
          },
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: BlocBuilder<KycIdentCubit, KycIdentState>(
                      builder: (context, state) {
                        if (state is KycIdentLoading) {
                          return FilledButton.icon(
                            onPressed: null,
                            icon: SizedBox(
                              height: 14,
                              width: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: RealUnitColors.basic.black.withValues(alpha: 0.5),
                              ),
                            ),
                            label: Text(S.of(context).next),
                          );
                        }
                        return FilledButton(
                          onPressed: () {
                            context.read<KycIdentCubit>().startIdent(accessToken);
                          },
                          child: Text(S.of(context).next),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
