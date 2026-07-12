import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/screens/hardware_connect_bitbox/bitbox_address_recovery_page.dart';
import 'package:realunit_wallet/screens/hardware_connect_bitbox/bloc/connect_bitbox_cubit.dart';
import 'package:realunit_wallet/screens/hardware_connect_bitbox/connect_bitbox_view.dart';

import '../../../helper/helper.dart';

class _MockConnectBitboxCubit extends MockCubit<BitboxConnectionState>
    implements ConnectBitboxCubit {}

void main() {
  late _MockConnectBitboxCubit cubit;

  setUp(() {
    cubit = _MockConnectBitboxCubit();
  });

  void stubState(BitboxConnectionState state) {
    when(() => cubit.state).thenReturn(state);
    whenListen(
      cubit,
      const Stream<BitboxConnectionState>.empty(),
      initialState: state,
    );
  }

  // ConnectBitboxCubit starts a periodic BitBox scan timer in its constructor,
  // so BitboxAddressRecoveryPage can't be pumped deterministically; we render
  // its shared [ConnectBitboxView] instead. It documents the recovery screen's
  // optics, byte-identical to connect_bitbox_page_default, not the page wiring.
  Widget buildSubject() => Scaffold(
        body: BlocProvider<ConnectBitboxCubit>.value(
          value: cubit,
          child: ConnectBitboxView(onFinish: (_) {}, onCancel: () {}),
        ),
      );

  group('$BitboxAddressRecoveryPage', () {
    goldenTest(
      'not connected default state',
      fileName: 'bitbox_address_recovery_page_default',
      constraints: phoneConstraints,
      builder: () {
        stubState(BitboxNotConnected());
        return wrapForGolden(buildSubject());
      },
    );
  });
}
