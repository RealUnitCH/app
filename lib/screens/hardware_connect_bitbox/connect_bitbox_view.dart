import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/utils/device_info.dart';
import 'package:realunit_wallet/screens/hardware_connect_bitbox/bloc/connect_bitbox_cubit.dart';
import 'package:realunit_wallet/screens/hardware_connect_bitbox/widgets/connect_content.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/handlebars.dart';

class ConnectBitboxView extends StatelessWidget {
  const ConnectBitboxView({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      width: .infinity,
      child: BlocListener<ConnectBitboxCubit, BitboxConnectionState>(
        listener: (context, state) async {
          if (state is BitboxFinishSetup) {
            if (context.mounted) context.read<HomeBloc>().add(LoadWalletEvent(state.wallet));
          }
          if (state is BitboxNotConnected) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Something went wrong. Please try to connect again.'),
                ),
              );
            }
          }
        },
        child: Padding(
          padding: const .symmetric(horizontal: 20.0),
          child: Column(
            mainAxisSize: .min,
            children: [
              Handlebars.horizontal(context, margin: const .only(top: 5), width: 36),
              BlocBuilder<ConnectBitboxCubit, BitboxConnectionState>(
                builder: (context, state) => Stack(
                  children: [
                    AnimatedSlide(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOut,
                      offset: state is BitboxNotConnected ? .zero : const Offset(-1.5, 0),
                      child: ConnectContent(
                        title: S.of(context).connectBitboxTitle,
                        imagePath: 'assets/images/illustrations/bitbox_connect.svg',
                        onCancel: context.pop,
                        child: Text(
                          DeviceInfo.instance.isIOS
                              ? S.of(context).connectBitboxContentIos
                              : S.of(context).connectBitboxContent,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: RealUnitColors.neutral500,
                          ),
                        ),
                      ),
                    ),
                    AnimatedSlide(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOut,
                      offset: state is BitboxConnecting ? .zero : const Offset(1.5, 0),
                      child: Column(
                        children: [
                          ConnectContent(
                            title: S.of(context).connectBitboxTitle,
                            imagePath: 'assets/images/illustrations/bitbox_connect.svg',
                            child: Column(
                              spacing: 40,
                              children: [
                                Text(
                                  'Device found, please check your Bitbox and follow the instructions, memorise the shown pairing code.',
                                  textAlign: .center,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: RealUnitColors.neutral500,
                                  ),
                                ),
                                const CupertinoActivityIndicator(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedSlide(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOut,
                      offset: state is BitboxCheckHash || state is BitboxPairing
                          ? Offset.zero
                          : const Offset(1.5, 0),
                      child: ConnectContent(
                        title: S.of(context).connectBitboxTitle,
                        imagePath: 'assets/images/illustrations/bitbox_connected.svg',
                        onConfirm: state is BitboxCheckHash
                            ? () => context.read<ConnectBitboxCubit>().confirmPairing()
                            : null,
                        onCancel: state is BitboxCheckHash ? context.pop : null,
                        child: Column(
                          spacing: 16,
                          children: [
                            SizedBox(
                              child: Text(
                                'Verify this code matches the one shown on your BitBox device, then confirm.',
                                textAlign: .center,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: RealUnitColors.neutral500,
                                ),
                              ),
                            ),
                            state is BitboxPairing
                                ? const CupertinoActivityIndicator()
                                : Container(
                                    padding: const .all(16),
                                    decoration: BoxDecoration(
                                      color: RealUnitColors.realUnitBlue.withValues(alpha: 0.1),
                                      borderRadius: .circular(12),
                                    ),
                                    child: Text(
                                      state is BitboxCheckHash ? state.channelHash : '',
                                      textAlign: .center,
                                      style: Theme.of(context).textTheme.headlineSmall,
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedSlide(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOut,
                      offset: state is BitboxConnected ? Offset.zero : const Offset(1.5, 0),
                      child: ConnectContent(
                        title: 'Connected',
                        onConfirm: () => context.read<ConnectBitboxCubit>().finishSetup(),
                        imagePath: 'assets/images/illustrations/bitbox_connected.svg',
                        child: Text(
                          S.of(context).connectedBitboxContent,
                          textAlign: .center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: RealUnitColors.neutral500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
