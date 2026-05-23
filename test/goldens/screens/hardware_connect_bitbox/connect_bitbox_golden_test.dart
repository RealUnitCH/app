import 'package:alchemist/alchemist.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/screens/hardware_connect_bitbox/bloc/connect_bitbox_cubit.dart';
import 'package:realunit_wallet/screens/hardware_connect_bitbox/connect_bitbox_view.dart';

import '../../../helper/helper.dart';

class _MockConnectBitboxCubit extends MockCubit<BitboxConnectionState>
    implements ConnectBitboxCubit {}

void main() {
  late _MockConnectBitboxCubit cubit;

  setUp(() {
    cubit = _MockConnectBitboxCubit();
    final state = BitboxNotConnected();
    when(() => cubit.state).thenReturn(state);
    whenListen(
      cubit,
      const Stream<BitboxConnectionState>.empty(),
      initialState: state,
    );
  });

  Widget buildSubject() => Scaffold(
        body: BlocProvider<ConnectBitboxCubit>.value(
          value: cubit,
          child: ConnectBitboxView(onFinish: (_) {}),
        ),
      );

  group('$ConnectBitboxView', () {
    goldenTest(
      'not connected default state',
      fileName: 'connect_bitbox_page_default',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      builder: () => wrapForGolden(buildSubject()),
    );
  });
}
