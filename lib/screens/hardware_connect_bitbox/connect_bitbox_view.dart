import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/hardware_connect_bitbox/bloc/connect_bitbox_cubit.dart';
import 'package:realunit_wallet/screens/hardware_connect_bitbox/widgets/connect_content.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/styles/styles.dart';
import 'package:realunit_wallet/widgets/handlebars.dart';

class ConnectBitboxView extends StatefulWidget {
  const ConnectBitboxView({super.key});

  @override
  State<StatefulWidget> createState() => _ConnectBitboxViewState();
}

class _ConnectBitboxViewState extends State<ConnectBitboxView> {
  @override
  Widget build(BuildContext context) => BlocListener<ConnectBitboxCubit, BitboxConnectionState>(
        listener: (context, state) {
          if (state is BitboxConnected) {
            context.read<HomeBloc>().add(LoadWalletEvent(state.wallet));
          }
        },
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              Handlebars.horizontal(context, margin: EdgeInsets.only(top: 5), width: 36),
              BlocBuilder<ConnectBitboxCubit, BitboxConnectionState>(
                builder: (context, state) => Stack(children: [
                  AnimatedSlide(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                    offset: state is BitboxNotConnected ? Offset.zero : const Offset(-1.2, 0),
                    child: ConnectContent(
                      title: S.of(context).connect_bitbox_title,
                      content: Platform.isIOS
                          ? S.of(context).connect_bitbox_content_ios
                          : S.of(context).connect_bitbox_content,
                      imagePath: "assets/images/illustrations/bitbox_connect.svg",
                    ),
                  ),
                  AnimatedSlide(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                    offset: state is BitboxFound ? Offset.zero : const Offset(1.2, 0),
                    child: ConnectContent(
                      title: S.of(context).connected_bitbox_title,
                      content: S.of(context).connected_bitbox_content,
                      imagePath: "assets/images/illustrations/bitbox_connected.svg",
                    ),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 28, bottom: 54),
                child: ElevatedButton(
                  style: kFullwidthGrayButtonStyle,
                  onPressed: context.pop,
                  child: Text(S.of(context).cancel),
                ),
              )
            ],
          ),
        ),
      );
}
