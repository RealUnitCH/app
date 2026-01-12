import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/styles/colors.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    context.read<HomeBloc>().add(const LoadCurrentWalletEvent());

    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CupertinoActivityIndicator(
          color: DEuroColors.dEuroGold,
        ),
      ),
    );
  }
}
