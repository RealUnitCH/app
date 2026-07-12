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

  // [BitboxAddressRecoveryPage] is a thin getIt-wiring host around the shared
  // [ConnectBitboxView]: the ConnectBitboxCubit it builds auto-starts a BLE
  // scan timer in its constructor, so the page itself cannot be pumped
  // deterministically. We render the exact view the page hosts over a mocked
  // cubit instead, wiring the non-null onCancel the recovery host supplies
  // (the initial-pairing host leaves it null). Same seam as
  // connect_bitbox_golden_test.dart. The not-connected default is the stable
  // state the user lands on; the animating/transient states are covered by the
  // shared view's own golden suite.
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
