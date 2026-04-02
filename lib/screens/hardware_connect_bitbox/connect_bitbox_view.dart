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
                SnackBar(
                  content: Text(S.of(context).connectBitboxFailed),
                ),
              );
            }
          }
        },
        child: Padding(
          padding: const .symmetric(horizontal: 20.0),
          child: Column(
            children: [
              Handlebars.horizontal(context, margin: const .only(top: 5), width: 36),
              Expanded(
                child: BlocBuilder<ConnectBitboxCubit, BitboxConnectionState>(
                  builder: (context, state) => switch (state) {
                    BitboxConnecting() => ConnectContent(
                      title: S.of(context).connectBitboxTitle,
                      imagePath: 'assets/images/illustrations/bitbox_connect.svg',
                      child: Column(
                        spacing: 40,
                        children: [
                          Text(
                            S.of(context).connectBitboxConnecting,
                            textAlign: .center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: RealUnitColors.neutral500,
                            ),
                          ),
                          const CupertinoActivityIndicator(),
                        ],
                      ),
                    ),
                    BitboxCheckHash(:final channelHash) => ConnectContent(
                      title: S.of(context).connectBitboxTitle,
                      imagePath: 'assets/images/illustrations/bitbox_connected.svg',
                      onConfirm: context.read<ConnectBitboxCubit>().confirmPairing,
                      onCancel: context.pop,
                      child: Column(
                        spacing: 16,
                        children: [
                          Text(
                            S.of(context).connectBitboxCheckPairingCode,
                            textAlign: .center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: RealUnitColors.neutral500,
                            ),
                          ),
                          Container(
                            padding: const .all(16),
                            decoration: BoxDecoration(
                              color: RealUnitColors.realUnitBlue.withValues(alpha: 0.1),
                              borderRadius: .circular(12),
                            ),
                            child: Text(
                              channelHash,
                              textAlign: .center,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                    BitboxPairing() => ConnectContent(
                      title: S.of(context).connectBitboxTitle,
                      imagePath: 'assets/images/illustrations/bitbox_connected.svg',
                      child: Column(
                        spacing: 40,
                        children: [
                          Text(
                            S.of(context).connectBitboxCheckPairingCode,
                            textAlign: .center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: RealUnitColors.neutral500,
                            ),
                          ),
                          const CupertinoActivityIndicator(),
                        ],
                      ),
                    ),
                    BitboxConnected() => ConnectContent(
                      title: S.of(context).connected,
                      imagePath: 'assets/images/illustrations/bitbox_connected.svg',
                      onConfirm: () => context.read<ConnectBitboxCubit>().finishSetup(),
                      child: Text(
                        S.of(context).connectedBitboxContent,
                        textAlign: .center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: RealUnitColors.neutral500,
                        ),
                      ),
                    ),
                    _ => ConnectContent(
                      title: S.of(context).connectBitboxTitle,
                      imagePath: 'assets/images/illustrations/bitbox_connect.svg',
                      onCancel: context.pop,
                      child: Text(
                        DeviceInfo.instance.isIOS
                            ? S.of(context).connectBitboxContentIos
                            : S.of(context).connectBitboxContent,
                        textAlign: .center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: RealUnitColors.neutral500,
                        ),
                      ),
                    ),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
