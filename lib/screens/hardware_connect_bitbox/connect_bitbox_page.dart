import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/screens/hardware_connect_bitbox/bloc/connect_bitbox_cubit.dart';
import 'package:realunit_wallet/screens/hardware_connect_bitbox/connect_bitbox_view.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/setup/di.dart';

class ConnectBitboxPage extends StatelessWidget {
  const ConnectBitboxPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => ConnectBitboxCubit(getIt<BitboxService>(), getIt<WalletService>()),
    child: BlocListener<ConnectBitboxCubit, BitboxConnectionState>(
      listener: (context, state) {
        if (state is BitboxConnected) {
          context.read<HomeBloc>().add(LoadWalletEvent(state.wallet));
        }
      },
      child: const ConnectBitboxView(),
    ),
  );
}
