import 'dart:typed_data';

import 'package:bitbox_flutter/bitbox_flutter.dart';
import 'package:bitbox_flutter/bitbox_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox_credentials.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/bitbox_exception.dart';

class _MockBitboxManager extends Mock implements BitboxManager {}

class _FakeDevice extends Fake implements BitboxDevice {}

void main() {
  late _MockBitboxManager manager;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    manager = _MockBitboxManager();
  });

  BitboxCredentials connected() =>
      BitboxCredentials('0x000000000000000000000000000000000000dead')..setBitbox(manager);

  group('$BitboxCredentials', () {
    test('isConnected is false until setBitbox is called', () {
      final c = BitboxCredentials('0x000000000000000000000000000000000000dead');
      expect(c.isConnected, isFalse);
    });

    test('setBitbox and clearBitbox toggle isConnected', () {
      final c = BitboxCredentials('0x000000000000000000000000000000000000dead');
      c.setBitbox(manager);
      expect(c.isConnected, isTrue);
      c.clearBitbox();
      expect(c.isConnected, isFalse);
    });

    test('signToSignature throws BitboxNotConnectedException when bitboxManager is null', () {
      final c = BitboxCredentials('0x000000000000000000000000000000000000dead');
      expect(
        () => c.signToSignature(Uint8List.fromList(List.filled(32, 0))),
        throwsA(isA<BitboxNotConnectedException>()),
      );
    });

    test('signToSignature strips the EIP-1559 type-prefix byte before sending', () async {
      final fakeSig = Uint8List.fromList(
        List<int>.filled(32, 0xAA) + List<int>.filled(32, 0xBB) + [0x01],
      );
      when(
        () => manager.signETHRLPTransaction(any(), any(), any(), any()),
      ).thenAnswer((_) async => fakeSig);

      final payload = Uint8List.fromList([0x02, 0xCA, 0xFE, 0xBA, 0xBE]);
      final sig = await connected().signToSignature(payload, chainId: 1, isEIP1559: true);

      expect(sig.v, 1, reason: 'EIP-1559 keeps the raw parity v as-is');
      final captured = verify(
        () => manager.signETHRLPTransaction(
          captureAny(),
          captureAny(),
          captureAny(),
          captureAny(),
        ),
      ).captured;
      expect(captured[2], 'cafebabe', reason: 'leading 0x02 must be stripped before hex-encoding');
    });

    test('signToSignature returns raw v for legacy (non-EIP-155) signatures', () async {
      // chainId=null, BitBox returns v in {27, 28}.
      final fakeSig = Uint8List.fromList(
        List<int>.filled(32, 0x11) + List<int>.filled(32, 0x22) + [27],
      );
      when(
        () => manager.signETHRLPTransaction(any(), any(), any(), any()),
      ).thenAnswer((_) async => fakeSig);

      final sig = await connected().signToSignature(Uint8List.fromList([0xDE, 0xAD]));
      expect(sig.v, 27);
    });

    test('signToSignature derives chainIdV for parity 0 (EIP-155)', () async {
      // chainId=1, EIP-155 v = chainId*2 + 35 = 37 (parity 0).
      final fakeSig = Uint8List.fromList(
        List<int>.filled(32, 0x11) + List<int>.filled(32, 0x22) + [37],
      );
      when(
        () => manager.signETHRLPTransaction(any(), any(), any(), any()),
      ).thenAnswer((_) async => fakeSig);

      final sig = await connected().signToSignature(Uint8List.fromList([0xDE, 0xAD]), chainId: 1);
      expect(sig.v, 37);
    });

    test('signToSignature derives chainIdV for parity 1 (EIP-155)', () async {
      final fakeSig = Uint8List.fromList(
        List<int>.filled(32, 0x11) + List<int>.filled(32, 0x22) + [38],
      );
      when(
        () => manager.signETHRLPTransaction(any(), any(), any(), any()),
      ).thenAnswer((_) async => fakeSig);

      final sig = await connected().signToSignature(Uint8List.fromList([0xDE, 0xAD]), chainId: 1);
      expect(sig.v, 38);
    });

    test('signPersonalMessage throws BitboxNotConnectedException when not connected', () {
      final c = BitboxCredentials('0x000000000000000000000000000000000000dead');
      expect(
        () => c.signPersonalMessage(Uint8List.fromList([1, 2, 3])),
        throwsA(isA<BitboxNotConnectedException>()),
      );
    });

    test('signPersonalMessage passes chainId and derivation path to the manager', () async {
      when(
        () => manager.signETHMessage(any(), any(), any()),
      ).thenAnswer((_) async => Uint8List.fromList(List.filled(65, 0x01)));

      final sig = await connected().signPersonalMessage(Uint8List.fromList([1, 2, 3]), chainId: 1);

      expect(sig.length, 65);
      final captured = verify(
        () => manager.signETHMessage(
          captureAny(),
          captureAny(),
          captureAny(),
        ),
      ).captured;
      expect(captured[0], 1);
      expect(captured[1], "m/44'/60'/0'/0/0");
    });

    test('signTypedDataV4 throws BitboxNotConnectedException when not connected', () {
      final c = BitboxCredentials('0x000000000000000000000000000000000000dead');
      expect(
        () => c.signTypedDataV4(1, '{"primaryType":"Foo"}'),
        throwsA(isA<BitboxNotConnectedException>()),
      );
    });

    test('signTypedDataV4 hex-encodes signature bytes with 0x prefix', () async {
      when(
        () => manager.signETHTypedMessage(any(), any(), any()),
      ).thenAnswer((_) async => Uint8List.fromList([0xCA, 0xFE, 0xBA, 0xBE]));

      final sig = await connected().signTypedDataV4(1, '{"primaryType":"Foo"}');
      expect(sig, '0xcafebabe');
    });

    test('serializes parallel signs through the static queue', () async {
      var inFlight = 0;
      var maxParallel = 0;
      when(() => manager.signETHTypedMessage(any(), any(), any())).thenAnswer((_) async {
        inFlight++;
        if (inFlight > maxParallel) maxParallel = inFlight;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        inFlight--;
        return Uint8List.fromList([0x01]);
      });

      final c = connected();
      await Future.wait([
        c.signTypedDataV4(1, '{"primaryType":"A"}'),
        c.signTypedDataV4(1, '{"primaryType":"B"}'),
        c.signTypedDataV4(1, '{"primaryType":"C"}'),
      ]);

      expect(maxParallel, 1);
    });

    test('queue continues after a sign throws (slot released in finally)', () async {
      // `_runOrThrowDisconnect` probes `manager.devices` on a thrown sign to
      // decide whether to relabel the error as BitboxNotConnectedException.
      // Stub it to a non-empty list so the original "first sign explodes"
      // survives — this test exercises the queue, not the disconnect path.
      when(() => manager.devices).thenAnswer((_) async => [_FakeDevice()]);

      var call = 0;
      when(() => manager.signETHTypedMessage(any(), any(), any())).thenAnswer((_) async {
        call++;
        if (call == 1) throw Exception('first sign explodes');
        return Uint8List.fromList([0x42]);
      });

      final c = connected();
      await expectLater(
        c.signTypedDataV4(1, '{"primaryType":"A"}'),
        throwsException,
      );
      final sig = await c
          .signTypedDataV4(1, '{"primaryType":"B"}')
          .timeout(const Duration(seconds: 1));
      expect(sig, '0x42');
    });
  });
}
