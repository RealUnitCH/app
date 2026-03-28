import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/utils/device_info.dart';
import 'package:realunit_wallet/screens/hardware_connect_bitbox/bloc/connect_bitbox_cubit.dart';
import 'package:realunit_wallet/screens/hardware_connect_bitbox/widgets/connect_content.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/styles.dart';
import 'package:realunit_wallet/widgets/handlebars.dart';

class ConnectBitboxView extends StatelessWidget {
  const ConnectBitboxView({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Handlebars.horizontal(context, margin: const EdgeInsets.only(top: 5), width: 36),
          BlocBuilder<ConnectBitboxCubit, BitboxConnectionState>(
            builder: (context, state) => Stack(
              children: [
                // Initial state - searching for device or connecting
                AnimatedSlide(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                  offset: (state is BitboxNotConnected || state is BitboxConnecting)
                      ? Offset.zero
                      : const Offset(-1.2, 0),
                  child: Column(
                    children: [
                      ConnectContent(
                        title: S.of(context).connectBitboxTitle,
                        content: DeviceInfo.instance.isIOS
                            ? S.of(context).connectBitboxContentIos
                            : S.of(context).connectBitboxContent,
                        imagePath: 'assets/images/illustrations/bitbox_connect.svg',
                      ),
                      if (state is BitboxConnecting)
                        const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: CupertinoActivityIndicator(),
                        ),
                    ],
                  ),
                ),
                // Pairing state - show hash and confirm button
                AnimatedSlide(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                  offset: state is BitboxPairing ? Offset.zero : const Offset(1.2, 0),
                  child: _buildPairingContent(context, state),
                ),
                // Connected state
                AnimatedSlide(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                  offset: state is BitboxConnected ? Offset.zero : const Offset(1.2, 0),
                  child: ConnectContent(
                    title: S.of(context).connectedBitboxTitle,
                    content: S.of(context).connectedBitboxContent,
                    imagePath: 'assets/images/illustrations/bitbox_connected.svg',
                  ),
                ),
              ],
            ),
          ),
          BlocBuilder<ConnectBitboxCubit, BitboxConnectionState>(
            builder: (context, state) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: state is BitboxPairing
                  ? Column(
                      spacing: 12,
                      children: [
                        ElevatedButton(
                          style: kFullwidthPrimaryButtonStyle,
                          onPressed: () => context.read<ConnectBitboxCubit>().confirmPairing(),
                          child: Text(S.of(context).confirm),
                        ),
                        ElevatedButton(
                          style: kFullwidthGrayButtonStyle,
                          onPressed: context.pop,
                          child: Text(S.of(context).cancel),
                        ),
                      ],
                    )
                  : ElevatedButton(
                      style: kFullwidthGrayButtonStyle,
                      onPressed: context.pop,
                      child: Text(S.of(context).cancel),
                    ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildPairingContent(BuildContext context, BitboxConnectionState state) {
    final hash = state is BitboxPairing ? state.channelHash : '';
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 40, bottom: 20),
          child: Icon(Icons.security, size: 80, color: RealUnitColors.realUnitBlue),
        ),
        Text(
          'Verify Pairing Code',
          textAlign: TextAlign.center,
          style: kBottomSheetTitleTextStyle,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: RealUnitColors.realUnitBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            hash,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontFamily: 'monospace',
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 330,
          child: Text(
            'Verify this code matches the one shown on your BitBox device, then confirm on both.',
            textAlign: TextAlign.center,
            style: kBottomSheetContentTextStyle,
          ),
        ),
      ],
    );
  }
}
