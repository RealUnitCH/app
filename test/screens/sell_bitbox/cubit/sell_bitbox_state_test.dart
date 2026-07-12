// We deliberately use non-const constructors throughout this file so the
// generative constructor lines get counted as executed in the coverage
// report. Const-only construction is a compile-time optimisation and is
// not visible to the line-coverage instrumentation.
// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/broadcast_transaction_request_dto.dart';
import 'package:realunit_wallet/screens/sell_bitbox/cubit/sell_bitbox_cubit.dart';

/// Equatable-`props` surface tests for `SellBitboxState` and every subclass.
///
/// The cubit-driven tests under `test/screens/sell_bitbox/` already exercise
/// the *transitions* between these states via `isA<>()` matchers, but they
/// never hit the bare `props` getters of the payload-carrying subclasses
/// (`SellBitboxAwaitingSwapConfirm`, `SellBitboxAwaitingDepositConfirm`,
/// `SellBitboxDepositRetry`, `SellBitboxError`) — and they never construct
/// the empty marker states (`SellBitboxBitboxRequired`, …) outside the
/// cubit. These tests close that gap so the value-type file lands at 100%.
void main() {
  const broadcastA = BroadcastTransactionRequestDto(
    unsignedTx: 'tx-a',
    r: 'r-a',
    s: 's-a',
    v: 27,
  );
  const broadcastB = BroadcastTransactionRequestDto(
    unsignedTx: 'tx-b',
    r: 'r-b',
    s: 's-b',
    v: 28,
  );

  group('SellBitboxState base + empty marker subclasses', () {
    test('base props default is empty', () {
      final state = SellBitboxBitboxRequired();
      expect(state.props, isEmpty);
    });

    test('SellBitboxBitboxRequired instances are equal', () {
      final a = SellBitboxBitboxRequired();
      final b = SellBitboxBitboxRequired();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('SellBitboxCheckingEth instances are equal', () {
      final a = SellBitboxCheckingEth();
      final b = SellBitboxCheckingEth();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('SellBitboxRequestingFaucet instances are equal', () {
      final a = SellBitboxRequestingFaucet();
      final b = SellBitboxRequestingFaucet();
      expect(a, equals(b));
    });

    test('SellBitboxWaitingForEth instances are equal', () {
      final a = SellBitboxWaitingForEth();
      final b = SellBitboxWaitingForEth();
      expect(a, equals(b));
    });

    test('SellBitboxEthReady instances are equal', () {
      final a = SellBitboxEthReady();
      final b = SellBitboxEthReady();
      expect(a, equals(b));
    });

    test('SellBitboxPreparingSwap instances are equal', () {
      final a = SellBitboxPreparingSwap();
      final b = SellBitboxPreparingSwap();
      expect(a, equals(b));
    });

    test('SellBitboxSwapping instances are equal', () {
      final a = SellBitboxSwapping();
      final b = SellBitboxSwapping();
      expect(a, equals(b));
    });

    test('SellBitboxDepositing instances are equal', () {
      final a = SellBitboxDepositing();
      final b = SellBitboxDepositing();
      expect(a, equals(b));
    });

    test('SellBitboxSuccess instances are equal', () {
      final a = SellBitboxSuccess();
      final b = SellBitboxSuccess();
      expect(a, equals(b));
    });
  });

  group('SellBitboxAwaitingSwapConfirm', () {
    test('same raw transactions are equal and props match', () {
      final a = SellBitboxAwaitingSwapConfirm('raw-swap', 'raw-deposit');
      final b = SellBitboxAwaitingSwapConfirm('raw-swap', 'raw-deposit');

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a.props, ['raw-swap', 'raw-deposit']);
    });

    test('different raw swap transactions are unequal', () {
      final a = SellBitboxAwaitingSwapConfirm('raw-swap', 'raw-deposit');
      final b = SellBitboxAwaitingSwapConfirm('raw-swap-OTHER', 'raw-deposit');
      expect(a, isNot(equals(b)));
    });

    test('different raw deposit transactions are unequal', () {
      final a = SellBitboxAwaitingSwapConfirm('raw-swap', 'raw-deposit');
      final b = SellBitboxAwaitingSwapConfirm('raw-swap', 'raw-deposit-OTHER');
      expect(a, isNot(equals(b)));
    });
  });

  group('SellBitboxAwaitingDepositConfirm', () {
    test('same payload is equal and props match', () {
      final a = SellBitboxAwaitingDepositConfirm(broadcastA, 'raw-deposit');
      final b = SellBitboxAwaitingDepositConfirm(broadcastA, 'raw-deposit');

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a.props, [broadcastA, 'raw-deposit']);
    });

    test('different raw deposit transactions are unequal', () {
      final a = SellBitboxAwaitingDepositConfirm(broadcastA, 'raw-deposit');
      final b = SellBitboxAwaitingDepositConfirm(broadcastA, 'raw-deposit-OTHER');
      expect(a, isNot(equals(b)));
    });
  });

  group('SellBitboxDepositRetry', () {
    test('same payload is equal and props match', () {
      final a = SellBitboxDepositRetry(broadcastA, broadcastB, 'boom');
      final b = SellBitboxDepositRetry(broadcastA, broadcastB, 'boom');

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a.props, [broadcastA, broadcastB, null, 'boom']);
    });

    test('different error messages are unequal', () {
      final a = SellBitboxDepositRetry(broadcastA, broadcastB, 'boom');
      final b = SellBitboxDepositRetry(broadcastA, broadcastB, 'other');
      expect(a, isNot(equals(b)));
    });

    test('different broadcastTxHash values are unequal', () {
      final a = SellBitboxDepositRetry(broadcastA, broadcastB, 'boom');
      final b = SellBitboxDepositRetry(broadcastA, broadcastB, 'boom', broadcastTxHash: '0xtxhash');
      expect(a, isNot(equals(b)));
      expect(b.props, [broadcastA, broadcastB, '0xtxhash', 'boom']);
    });
  });

  group('SellBitboxError', () {
    test('same message is equal and props match', () {
      final a = SellBitboxError('network down');
      final b = SellBitboxError('network down');

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a.props, ['network down']);
    });

    test('different messages are unequal', () {
      final a = SellBitboxError('network down');
      final b = SellBitboxError('signing failed');
      expect(a, isNot(equals(b)));
    });
  });

  group('SellBitboxState (cross-subclass identity)', () {
    test('different empty markers are not equal to each other', () {
      // Equatable's runtimeType check guarantees this even though both
      // subclasses inherit the empty `props => []` default.
      expect(SellBitboxBitboxRequired(), isNot(equals(SellBitboxCheckingEth())));
      expect(SellBitboxPreparingSwap(), isNot(equals(SellBitboxSwapping())));
      expect(SellBitboxDepositing(), isNot(equals(SellBitboxSuccess())));
    });

    test('payload-carrying state is not equal to a payload-less state', () {
      final err = SellBitboxError('boom');
      expect(err, isNot(equals(SellBitboxSuccess())));
    });
  });
}
