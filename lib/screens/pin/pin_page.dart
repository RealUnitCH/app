import 'package:realunit_wallet/screens/pin/bloc/pin_cubit.dart';
import 'package:realunit_wallet/screens/pin/pin_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PinPage extends StatelessWidget {
  const PinPage({super.key, required this.onSuccess});

  final Function (String database) onSuccess;

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => PinCubit(4, onSuccess),
        child: PinView(),
      );
}
