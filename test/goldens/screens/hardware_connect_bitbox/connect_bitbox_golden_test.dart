import 'package:bitbox_flutter/bitbox_flutter.dart' as sdk;
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/screens/hardware_connect_bitbox/bloc/connect_bitbox_cubit.dart';
import 'package:realunit_wallet/screens/hardware_connect_bitbox/connect_bitbox_view.dart';

import '../../../helper/helper.dart';

class _MockConnectBitboxCubit extends MockCubit<BitboxConnectionState>
    implements ConnectBitboxCubit {}

class _FakeBitboxDevice extends Fake implements sdk.BitboxDevice {}

class _MockBitboxWallet extends Mock implements BitboxWallet {}

void main() {
  late _MockConnectBitboxCubit cubit;
  late _FakeBitboxDevice device;
  late _MockBitboxWallet wallet;

  setUp(() {
    cubit = _MockConnectBitboxCubit();
    device = _FakeBitboxDevice();
    wallet = _MockBitboxWallet();
  });

  void stubState(BitboxConnectionState state) {
    when(() => cubit.state).thenReturn(state);
    whenListen(
      cubit,
      const Stream<BitboxConnectionState>.empty(),
      initialState: state,
    );
  }

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
      builder: () {
        stubState(BitboxNotConnected());
        return wrapForGolden(buildSubject());
      },
    );

    goldenTest(
      'connecting state — spinner, no buttons',
      fileName: 'connect_bitbox_page_connecting',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      // CupertinoActivityIndicator animates indefinitely;
      // pumpAndSettle (default) would time out.
      pumpBeforeTest: pumpOnce,
      builder: () {
        stubState(BitboxConnecting(device));
        return wrapForGolden(buildSubject());
      },
    );

    goldenTest(
      'check hash state — pairing-code pill + confirm/cancel',
      fileName: 'connect_bitbox_page_check_hash',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      builder: () {
        // Fixed hash so the rendered pill is deterministic across regens.
        stubState(BitboxCheckHash(device, '01:23:45:67:89:AB'));
        return wrapForGolden(buildSubject());
      },
    );

    goldenTest(
      'signature failed — retry + continue-anyway',
      fileName: 'connect_bitbox_page_signature_failed',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      builder: () {
        stubState(BitboxSignatureFailed(wallet));
        return wrapForGolden(buildSubject());
      },
    );
  });
}
