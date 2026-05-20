import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/screens/restore_wallet/cubit/restore_wallet/restore_wallet_cubit.dart';
import 'package:realunit_wallet/screens/restore_wallet/cubit/validate_seed/validate_seed_cubit.dart';
import 'package:realunit_wallet/screens/restore_wallet/restore_wallet_view.dart';
import 'package:realunit_wallet/setup/di.dart';

class RestoreWalletPage extends StatelessWidget {
  const RestoreWalletPage({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) => RestoreWalletCubit(
          getIt<WalletService>(),
          // DfxKycService is the smallest concrete DFXAuthService — only used
          // here as a transport for ensureSignatureFor(account).
          getIt<DfxKycService>(),
        ),
      ),
      BlocProvider(
        create: (_) => ValidateSeedCubit(
          getIt<WalletService>(),
        ),
      ),
    ],
    child: const RestoreWalletView(),
  );
}
