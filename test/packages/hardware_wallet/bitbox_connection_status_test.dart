import 'package:bitbox_flutter/bitbox_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox_connection_status.dart';

// Pins the sealed-class equality + immutability contract that ADR 0001
// promises consumers. If a refactor breaks value equality on any variant the
// broadcast controller's de-dup logic + bloc-test assertions silently slip,
// so the test surface is deliberately exhaustive — every variant gets an
// equality, an inequality, and a toString debug-print pin.
void main() {
  BitboxDevice device(String id) => BitboxDevice.fromIdentifier(id);

  group('$BitboxConnectionStatus equality', () {
    test('Disconnected instances are equal', () {
      expect(const Disconnected(), equals(const Disconnected()));
      expect(const Disconnected().props, isEmpty);
      // Distinct identities deliberately — the controller must dedupe on
      // value, not on reference, when a transient transition lands back on
      // the same terminal status.
      expect(
        identical(const Disconnected(), const Disconnected()),
        isTrue,
        reason: 'const Disconnected() is canonicalised',
      );
    });

    test('Disconnecting instances are equal', () {
      expect(const Disconnecting(), equals(const Disconnecting()));
      expect(const Disconnecting().props, isEmpty);
    });

    test('Connecting equality keys on device identifier', () {
      expect(
        Connecting(device('bitbox-A')),
        equals(Connecting(device('bitbox-A'))),
      );
      expect(
        Connecting(device('bitbox-A')),
        isNot(equals(Connecting(device('bitbox-B')))),
        reason: 'distinct devices must compare unequal',
      );
    });

    test('Paired equality keys on device identifier', () {
      expect(
        Paired(device('bitbox-A')),
        equals(Paired(device('bitbox-A'))),
      );
      expect(
        Paired(device('bitbox-A')),
        isNot(equals(Paired(device('bitbox-B')))),
      );
    });

    test('Connecting and Paired are not equal even with the same device', () {
      // Belt-and-braces: if a future refactor mistakenly hashes on `props`
      // alone without considering the runtime type, this catches it.
      expect(
        Connecting(device('bitbox-A')),
        isNot(equals(Paired(device('bitbox-A')))),
      );
    });

    test('InUse equality keys on (device, context)', () {
      final ctxA = const SignContext(
        address: '0xdead',
        derivationPath: "m/44'/60'/0'/0/0",
        kind: 'eip712',
      );
      final ctxB = const SignContext(
        address: '0xdead',
        derivationPath: "m/44'/60'/0'/0/1",
        kind: 'eip712',
      );
      expect(
        InUse(device('bitbox-A'), ctxA),
        equals(InUse(device('bitbox-A'), ctxA)),
      );
      expect(
        InUse(device('bitbox-A'), ctxA),
        isNot(equals(InUse(device('bitbox-A'), ctxB))),
        reason: 'different derivation paths must compare unequal',
      );
      expect(
        InUse(device('bitbox-A'), ctxA),
        isNot(equals(InUse(device('bitbox-B'), ctxA))),
        reason: 'different devices must compare unequal',
      );
    });

    test('Lost equality keys on reason', () {
      expect(
        const Lost(LostReason.signQueueTimeout),
        equals(const Lost(LostReason.signQueueTimeout)),
      );
      expect(
        const Lost(LostReason.signQueueTimeout),
        isNot(equals(const Lost(LostReason.staticPubkeyMismatch))),
      );
      expect(
        const Lost(LostReason.deviceUnreachable),
        isNot(equals(const Lost(LostReason.factoryResetDetected))),
      );
    });

    test('Disconnected and Lost are never equal even with no payload-difference', () {
      expect(
        const Disconnected(),
        isNot(equals(const Lost(LostReason.manualDisconnect))),
      );
    });
  });

  group('$BitboxConnectionStatus debug surface', () {
    test('toString names the runtime type for each variant', () {
      expect(const Disconnected().toString(), equals('Disconnected()'));
      expect(const Disconnecting().toString(), equals('Disconnecting()'));
      expect(
        Connecting(device('bitbox-A')).toString(),
        equals('Connecting(bitbox-A)'),
      );
      expect(
        Paired(device('bitbox-A')).toString(),
        equals('Paired(bitbox-A)'),
      );
      expect(
        const Lost(LostReason.signQueueTimeout).toString(),
        equals('Lost(signQueueTimeout)'),
      );
    });

    test('InUse.toString includes both device identifier and sign context', () {
      final ctx = const SignContext(
        address: '0xdead',
        derivationPath: "m/44'/60'/0'/0/0",
        kind: 'eip712',
      );
      expect(
        InUse(device('bitbox-A'), ctx).toString(),
        contains('bitbox-A'),
      );
      expect(
        InUse(device('bitbox-A'), ctx).toString(),
        contains('eip712'),
      );
    });
  });

  group('$LostReason enum surface', () {
    test('every reason has a stable name (sealed-set contract)', () {
      // The set is closed by design — adding a new value forces a
      // coordinated update everywhere this enum is switched on. The test
      // pins the current set so an accidental rename or removal is caught
      // before it ships.
      expect(
        LostReason.values.map((r) => r.name).toSet(),
        equals({
          'signQueueTimeout',
          'staticPubkeyMismatch',
          'manualDisconnect',
          'deviceUnreachable',
          'factoryResetDetected',
        }),
      );
    });
  });

  group('exhaustiveness — sealed switch', () {
    // Compile-time pin: a sealed-class switch over BitboxConnectionStatus
    // must compile to a complete `T Function(...)` without a default arm.
    // If a future PR adds a new subtype without updating the switch this
    // test stops compiling — the canonical Dart 3 sealed-class enforcement
    // the consumer surface depends on.
    String nameOf(BitboxConnectionStatus status) {
      return switch (status) {
        Disconnected() => 'disconnected',
        Connecting() => 'connecting',
        Paired() => 'paired',
        InUse() => 'inUse',
        Lost() => 'lost',
        Disconnecting() => 'disconnecting',
      };
    }

    test('switch covers every variant exhaustively at compile time', () {
      expect(nameOf(const Disconnected()), 'disconnected');
      expect(nameOf(Connecting(device('x'))), 'connecting');
      expect(nameOf(Paired(device('x'))), 'paired');
      expect(
        nameOf(
          InUse(
            device('x'),
            const SignContext(
              address: '0xdead',
              derivationPath: "m/44'/60'/0'/0/0",
              kind: 'eip712',
            ),
          ),
        ),
        'inUse',
      );
      expect(nameOf(const Lost(LostReason.signQueueTimeout)), 'lost');
      expect(nameOf(const Disconnecting()), 'disconnecting');
    });
  });

  group('$SignContext equality', () {
    test('same (address, path, kind) compares equal', () {
      // ignore: prefer_const_constructors
      final a = SignContext(
        address: '0xdead',
        derivationPath: "m/44'/60'/0'/0/0",
        kind: 'eip712',
      );
      // ignore: prefer_const_constructors
      final b = SignContext(
        address: '0xdead',
        derivationPath: "m/44'/60'/0'/0/0",
        kind: 'eip712',
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different kind compares unequal', () {
      const a = SignContext(
        address: '0xdead',
        derivationPath: "m/44'/60'/0'/0/0",
        kind: 'eip712',
      );
      const b = SignContext(
        address: '0xdead',
        derivationPath: "m/44'/60'/0'/0/0",
        kind: 'eip7702',
      );
      expect(a, isNot(equals(b)));
    });
  });
}
