import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/screens/debug_auth/cubit/debug_auth_cubit.dart';
import 'package:realunit_wallet/screens/debug_auth/debug_auth_view.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DebugAuthPage extends StatelessWidget {
  const DebugAuthPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => DebugAuthCubit(
      getIt<AppStore>(),
      getIt<SharedPreferences>(),
    ),
    child: const DebugAuthView(),
  );
}
