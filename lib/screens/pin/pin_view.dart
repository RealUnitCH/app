import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/screens/pin/bloc/pin_cubit.dart';
import 'package:realunit_wallet/screens/pin/widgets/pin_indicator.dart';
import 'package:realunit_wallet/widgets/number_pad.dart';

class PinView extends StatelessWidget {
  const PinView({super.key});

  static const _kPadding = EdgeInsets.only(left: 26, right: 26, bottom: 10);

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: BlocListener<PinCubit, PinState>(
            listener: (_, __) {},
            child: BlocBuilder<PinCubit, PinState>(
              builder: (context, state) => Column(
                children: [
                  Expanded(
                    child: Center(
                      child: PinIndicator(
                        pinLength: state.pin.length,
                        expectedPinLength: context.read<PinCubit>().maxPinLength,
                        wrongPin: state.wrongTry,
                      ),
                    ),
                  ),
                  NumberPad(
                    onNumberPressed: (index) => context.read<PinCubit>().amountAdd(index),
                    onDeletePressed: () => context.read<PinCubit>().amountDelete(),
                  ),
                  Padding(
                    padding: _kPadding,
                    child: TextButton(onPressed: () {}, child: const Text("Reset Wallet")),
                  )
                ],
              ),
            ),
          ),
        ),
      );
}
