import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/screens/restore_wallet/bloc/restore_wallet_cubit.dart';
import 'package:realunit_wallet/screens/restore_wallet/cubit/validate_seed_cubit.dart';
import 'package:realunit_wallet/screens/restore_wallet/restore_wallet_view.dart';

class RestoreWalletPage extends StatelessWidget {
  const RestoreWalletPage({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => RestoreWalletCubit(
              getIt<WalletService>(),
            ),
          ),
          BlocProvider(
            create: (_) => ValidateSeedCubit(),
          ),
        ],
        child: RestoreWalletView(),
      );
}
