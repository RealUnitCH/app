import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/sell_bitbox/cubit/sell_bitbox_cubit.dart';
import 'package:realunit_wallet/styles/colors.dart';

class SellBitboxEthStep extends StatelessWidget {
  const SellBitboxEthStep({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SellBitboxCubit, SellBitboxState>(
      builder: (context, state) {
        if (state is SellBitboxCheckingEth || state is SellBitboxRequestingFaucet) {
          return Column(
            mainAxisAlignment: .center,
            spacing: 24,
            children: [
              const CupertinoActivityIndicator(),
              Text(
                S.of(context).sellBitboxCheckingEth,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: .center,
              ),
            ],
          );
        }
        if (state is SellBitboxWaitingForEth) {
          return Column(
            spacing: 24,
            mainAxisAlignment: .center,
            children: [
              const Icon(
                Icons.hourglass_bottom_rounded,
                size: 64,
                color: RealUnitColors.realUnitBlue,
              ),
              Text(
                S.of(context).sellBitboxWaitingForEth,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: .center,
              ),
              Text(
                S.of(context).sellBitboxWaitingForEthDescription,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: RealUnitColors.neutral500,
                ),
                textAlign: .center,
              ),
              FilledButton(
                onPressed: null,
                child: Text(S.of(context).next),
              ),
            ],
          );
        }
        if (state is SellBitboxEthReady) {
          return Column(
            spacing: 24,
            mainAxisAlignment: .center,
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                size: 64,
                color: RealUnitColors.realUnitBlue,
              ),
              Text(
                S.of(context).sellBitboxEthReady,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: .center,
              ),
              Text(
                S.of(context).sellBitboxEthReadyDescription,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: RealUnitColors.neutral500,
                ),
                textAlign: .center,
              ),
              FilledButton(
                onPressed: () => context.read<SellBitboxCubit>().proceedToSwap(),
                child: Text(S.of(context).next),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
