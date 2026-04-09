import 'package:flutter/material.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/pin/constants/pin_constants.dart';
import 'package:realunit_wallet/screens/pin/widgets/pin_indicator.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/number_pad.dart';

class PinVerifyScaffold extends StatelessWidget {
  final String? description;
  final int pinEntryLength;
  final bool authFailed;
  final void Function(int digit) onDigitAdded;
  final VoidCallback onDeletePressed;
  final Widget? bottom;

  const PinVerifyScaffold({
    super.key,
    this.description,
    required this.pinEntryLength,
    required this.authFailed,
    required this.onDigitAdded,
    required this.onDeletePressed,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    backgroundColor: RealUnitColors.brand700,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                spacing: 4.0,
                children: [
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          spacing: 8.0,
                          children: [
                            Text(
                              S.of(context).pinVerify,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            Text(
                              description ?? S.of(context).pinVerifyDescription,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: RealUnitColors.neutral500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Column(
                          spacing: 16.0,
                          children: [
                            PinIndicator(
                              pinLength: pinEntryLength,
                              expectedPinLength: pinLength,
                              wrongPin: authFailed,
                            ),
                            Visibility(
                              visible: authFailed,
                              maintainSize: true,
                              maintainAnimation: true,
                              maintainState: true,
                              child: Text(
                                S.of(context).pinVerifyFailed,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: RealUnitColors.status.red600,
                                ),
                                textAlign: .center,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  NumberPad(
                    onNumberPressed: onDigitAdded,
                    onDeletePressed: onDeletePressed,
                  ),
                  if (bottom != null) bottom! else const SizedBox(height: 60.0),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
