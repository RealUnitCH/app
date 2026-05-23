// We deliberately use non-const constructors throughout this file so the
// generative constructor lines get counted as executed in the coverage
// report. Const-only construction is a compile-time optimisation and is
// not visible to the line-coverage instrumentation.
// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';

class _FakeWallet extends Fake implements AWallet {}

/// Equatable-`props` surface tests for `HomeEvent`.
///
/// `home_bloc_test.dart` exercises the *handler* side of every event, but it
/// constructs every const event as a compile-time constant — which doesn't
/// execute the const constructors at runtime. This file constructs each
/// subclass non-const (via `final`) so the constructor line and the props
/// getter both get exercised at runtime, lifting the file to 100%.
void main() {
  group('CheckWalletExistsEvent', () {
    test('two instances are equal and props are empty', () {
      final a = CheckWalletExistsEvent();
      final b = CheckWalletExistsEvent();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a.props, isEmpty);
    });
  });

  group('LoadCurrentWalletEvent', () {
    test('two instances are equal and props are empty', () {
      final a = LoadCurrentWalletEvent();
      final b = LoadCurrentWalletEvent();
      expect(a, equals(b));
      expect(a.props, isEmpty);
    });
  });

  group('DeleteCurrentWalletEvent', () {
    test('two instances are equal and props are empty', () {
      final a = DeleteCurrentWalletEvent();
      final b = DeleteCurrentWalletEvent();
      expect(a, equals(b));
      expect(a.props, isEmpty);
    });
  });

  group('LoadWalletEvent', () {
    test('same wallet is equal and props match', () {
      final AWallet wallet = _FakeWallet();
      final a = LoadWalletEvent(wallet);
      final b = LoadWalletEvent(wallet);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a.props, [wallet]);
    });

    test('different wallet instances are unequal', () {
      final AWallet w1 = _FakeWallet();
      final AWallet w2 = _FakeWallet();
      // Fakes compare by identity → the two events differ on their props.
      final a = LoadWalletEvent(w1);
      final b = LoadWalletEvent(w2);
      expect(a, isNot(equals(b)));
    });
  });

  group('SyncWalletServicesEvent', () {
    test('same wallet is equal and props match', () {
      final AWallet wallet = _FakeWallet();
      final a = SyncWalletServicesEvent(wallet);
      final b = SyncWalletServicesEvent(wallet);
      expect(a, equals(b));
      expect(a.props, [wallet]);
    });
  });

  group('CompleteOnboardingEvent', () {
    test('two instances are equal and props are empty', () {
      final a = CompleteOnboardingEvent();
      final b = CompleteOnboardingEvent();
      expect(a, equals(b));
      expect(a.props, isEmpty);
    });
  });

  group('AcceptSoftwareTermsEvent', () {
    test('two instances are equal and props are empty', () {
      final a = AcceptSoftwareTermsEvent();
      final b = AcceptSoftwareTermsEvent();
      expect(a, equals(b));
      expect(a.props, isEmpty);
    });
  });

  group('DebugAuthCompleteEvent', () {
    test('same address is equal and props match', () {
      final a = DebugAuthCompleteEvent(address: '0xabc');
      final b = DebugAuthCompleteEvent(address: '0xabc');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a.props, ['0xabc']);
    });

    test('different addresses are unequal', () {
      final a = DebugAuthCompleteEvent(address: '0xabc');
      final b = DebugAuthCompleteEvent(address: '0xdef');
      expect(a, isNot(equals(b)));
    });
  });

  group('HomeEvent (cross-subclass identity)', () {
    test('different payload-less subclasses are not equal', () {
      // Equatable's runtimeType check guarantees this even though they all
      // inherit `props => []` from the sealed base class.
      expect(CheckWalletExistsEvent(), isNot(equals(LoadCurrentWalletEvent())));
      expect(LoadCurrentWalletEvent(), isNot(equals(DeleteCurrentWalletEvent())));
      expect(CompleteOnboardingEvent(), isNot(equals(AcceptSoftwareTermsEvent())));
    });
  });
}
