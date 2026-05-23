// We deliberately use non-const constructors throughout this file so the
// generative constructor lines get counted as executed in the coverage
// report. Const-only construction is a compile-time optimisation and is
// not visible to the line-coverage instrumentation.
// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_issue.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_issue_reason.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_issue_state.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_issue_type.dart';
import 'package:realunit_wallet/screens/support/cubits/support_tickets/support_tickets_state.dart';

/// Equatable-`props` surface tests for `SupportTicketsState`.
SupportIssue _ticket({String uid = 'u1'}) => SupportIssue(
  uid: uid,
  state: SupportIssueState.created,
  type: SupportIssueType.genericIssue,
  reason: SupportIssueReason.other,
  name: 'n',
  created: DateTime.utc(2026, 5, 15),
  messages: const [],
);

void main() {
  group('SupportTicketsInitial', () {
    test('two instances are equal and props are empty', () {
      final a = SupportTicketsInitial();
      final b = SupportTicketsInitial();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a.props, isEmpty);
    });
  });

  group('SupportTicketsLoading', () {
    test('two instances are equal and props are empty', () {
      final a = SupportTicketsLoading();
      final b = SupportTicketsLoading();
      expect(a, equals(b));
      expect(a.props, isEmpty);
    });
  });

  group('SupportTicketsLoaded', () {
    test('same tickets list is equal and props match', () {
      final t = _ticket();
      final a = SupportTicketsLoaded([t]);
      final b = SupportTicketsLoaded([t]);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a.props, [
        [t],
      ]);
    });

    test('different tickets lists are unequal', () {
      final t1 = _ticket(uid: 'u1');
      final t2 = _ticket(uid: 'u2');
      final a = SupportTicketsLoaded([t1]);
      final b = SupportTicketsLoaded([t1, t2]);
      expect(a, isNot(equals(b)));
    });
  });

  group('SupportTicketsError', () {
    test('same message is equal and props match', () {
      final a = SupportTicketsError('boom');
      final b = SupportTicketsError('boom');
      expect(a, equals(b));
      expect(a.props, ['boom']);
    });

    test('different messages are unequal', () {
      final a = SupportTicketsError('boom');
      final b = SupportTicketsError('other');
      expect(a, isNot(equals(b)));
    });
  });

  group('SupportTicketsState (cross-subclass identity)', () {
    test('different empty subclasses are not equal', () {
      expect(SupportTicketsInitial(), isNot(equals(SupportTicketsLoading())));
    });

    test('Loaded vs Error are unequal', () {
      final loaded = SupportTicketsLoaded([_ticket()]);
      final err = SupportTicketsError('boom');
      expect(loaded, isNot(equals(err)));
    });
  });
}
