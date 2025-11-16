import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/models/blockchain.dart';
import 'package:realunit_wallet/screens/settings_edit_node/bloc/edit_node_cubit.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/styles.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SettingsNodesView extends StatelessWidget {
  SettingsNodesView({super.key, required this.blockchain});

  final Blockchain blockchain;
  final TextEditingController urlFieldController = TextEditingController();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: CupertinoNavigationBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: DEuroColors.anthracite,
              size: 24,
            ),
          ),
          middle: Text(
            blockchain.name,
            style: kPageTitleTextStyle,
          ),
          border: null,
        ),
        body: SingleChildScrollView(
          child: SizedBox(
            width: double.infinity,
            child: BlocBuilder<EditNodeCubit, EditNodeState>(
              builder: (context, state) {
                urlFieldController.text = state.node?.httpsUrl ?? '';
                return Column(children: [
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 26, right: 26, top: 26, bottom: 35),
                    child: TextField(
                      controller: urlFieldController,
                      decoration: InputDecoration(
                        hintText: "RPC-URL (https)",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: DEuroColors.dEuroBlue),
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: DEuroColors.dEuroBlue),
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: state.isSaving ? null : () => context
                        .read<EditNodeCubit>()
                        .saveHttpRPCUrl(urlFieldController.text),
                    style: kFullwidthBlueButtonStyle,
                    child: Text(
                      S.of(context).save,
                      textAlign: TextAlign.center,
                      style: kFullwidthBlueButtonTextStyle,
                    ),
                  ),
                ]);
              },
            ),
          ),
        ),
      );
}
