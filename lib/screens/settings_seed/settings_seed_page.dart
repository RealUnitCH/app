import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/screens/settings_seed/bloc/settings_seed_cubit.dart';
import 'package:realunit_wallet/screens/settings_seed/settings_seed_view.dart';
import 'package:realunit_wallet/setup/di.dart';

class SettingsSeedPage extends StatelessWidget {
  const SettingsSeedPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => SettingsSeedCubit(getIt<AppStore>()),
    child: const SettingsSeedView(),
  );
}
