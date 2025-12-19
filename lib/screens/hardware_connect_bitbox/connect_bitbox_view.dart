import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/hardware_connect_bitbox/bloc/connect_bitbox_cubit.dart';
import 'package:realunit_wallet/screens/hardware_connect_bitbox/widgets/connect_content.dart';
import 'package:realunit_wallet/styles/styles.dart';
import 'package:realunit_wallet/widgets/handlebars.dart';

class ConnectBitboxView extends StatelessWidget {
  const ConnectBitboxView({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Handlebars.horizontal(context, margin: EdgeInsets.only(top: 5), width: 36),
              BlocBuilder<ConnectBitboxCubit, BitboxConnectionState>(
                builder: (context, state) => Stack(
                  children: [
                    AnimatedSlide(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOut,
                      offset: state is BitboxNotConnected ? Offset.zero : const Offset(-1.2, 0),
                      child: ConnectContent(
                        title: S.of(context).connect_bitbox_title,
                        content: defaultTargetPlatform == TargetPlatform.iOS
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
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
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
