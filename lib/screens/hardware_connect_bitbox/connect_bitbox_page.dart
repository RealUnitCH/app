import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/screens/hardware_connect_bitbox/bloc/connect_bitbox_cubit.dart';
import 'package:realunit_wallet/screens/hardware_connect_bitbox/connect_bitbox_view.dart';

class ConnectBitboxPage extends StatelessWidget {
  const ConnectBitboxPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => ConnectBitboxCubit(getIt<BitboxService>(), getIt<WalletService>()),
        child: ConnectBitboxView(),
      );
}
