import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/screens/create_wallet/bloc/create_wallet_cubit.dart';
import 'package:realunit_wallet/screens/create_wallet/create_wallet_view.dart';
import 'package:realunit_wallet/setup/di.dart';

class CreateWalletPage extends StatelessWidget {
  const CreateWalletPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => CreateWalletCubit(
      getIt<WalletService>(),
      // DfxKycService is the smallest concrete DFXAuthService — only used here
      // as a transport for ensureSignatureFor(account).
      getIt<DfxKycService>(),
    )..createWallet(),
    child: const CreateWalletView(),
  );
}
