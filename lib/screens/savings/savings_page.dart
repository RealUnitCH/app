import 'package:deuro_wallet/di.dart';
import 'package:deuro_wallet/packages/service/app_store.dart';
import 'package:deuro_wallet/screens/savings/bloc/savings_bloc.dart';
import 'package:deuro_wallet/screens/savings/savings_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SavingsPage extends StatelessWidget {
  const SavingsPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => getIt<SavingsBloc>(),
        child: SavingsView(getIt<AppStore>()),
      );
}
