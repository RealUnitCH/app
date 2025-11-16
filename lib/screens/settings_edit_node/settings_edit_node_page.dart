import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/models/blockchain.dart';
import 'package:realunit_wallet/packages/repository/node_repository.dart';
import 'package:realunit_wallet/screens/settings_edit_node/bloc/edit_node_cubit.dart';
import 'package:realunit_wallet/screens/settings_edit_node/settings_edit_node_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsEditNodePage extends StatelessWidget {
  final Blockchain blockchain;

  const SettingsEditNodePage({super.key, required this.blockchain});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) =>
            EditNodeCubit(getIt<NodeRepository>(), blockchain)..loadNode(),
        child: SettingsNodesView(blockchain: blockchain,),
      );
}
