import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/kyc/cubits/kyc/kyc_cubit.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';
import 'package:realunit_wallet/widgets/scrollable_actions_layout.dart';

class KycManualReviewPage extends StatelessWidget {
  final String? rejectionMessage;

  const KycManualReviewPage({super.key, this.rejectionMessage});

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.headlineMedium;
    final labelStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: RealUnitColors.neutral500,
    );
    final sentence = rejectionMessage;
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).kyc),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: SafeArea(
          child: ScrollableActionsLayout(
            centerBody: true,
            body: Column(
              spacing: 8.0,
              children: [
                Text(
                  S.of(context).kycManualReviewTitle,
                  style: titleStyle,
                  textAlign: TextAlign.center,
                ),
                if (sentence != null && sentence.isNotEmpty) ...[
                  Text(
                    S.of(context).kycManualReviewRejectionLabel,
                    textAlign: TextAlign.center,
                    style: labelStyle,
                  ),
                  Text(
                    sentence,
                    style: titleStyle,
                    textAlign: TextAlign.center,
                  ),
                ],
                Text(
                  S.of(context).kycManualReviewDescription,
                  textAlign: TextAlign.center,
                  style: labelStyle,
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: AppFilledButton(
                  onPressed: () => context.read<KycCubit>().checkKyc(),
                  label: S.of(context).refresh,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
