import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/service/dfx/models/bank_account/bank_account.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/buy/buy_payment_info.dart';
import 'package:realunit_wallet/packages/service/dfx/models/pdf/balance_pdf_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/pdf/multi_receipt_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/pdf/pdf_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/pdf/single_receipt_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/dto/support_issue_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_issue.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_issue_reason.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_issue_state.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_issue_type.dart';
import 'package:realunit_wallet/styles/currency.dart';
import 'package:realunit_wallet/styles/language.dart';

void main() {
  group('$MultiReceiptDto.toJson', () {
    test('defaults currency to CHF and language to EN, renames txIds → txHashes', () {
      const dto = MultiReceiptDto(txIds: ['a', 'b']);

      expect(dto.toJson(), {'txHashes': ['a', 'b'], 'currency': 'CHF', 'language': 'EN'});
    });

    test('honours a custom currency', () {
      const dto = MultiReceiptDto(txIds: ['x'], currency: Currency.eur);

      expect(dto.toJson()['currency'], 'EUR');
    });

    test('honours a language override and uppercases the code', () {
      const dto = MultiReceiptDto(txIds: ['x'], language: Language.de);

      expect(dto.toJson()['language'], 'DE');
    });
  });

  group('$SingleReceiptDto.toJson', () {
    test('defaults currency to CHF and language to EN, renames txId → txHash', () {
      const dto = SingleReceiptDto(txId: '0xabc');

      expect(dto.toJson(), {'txHash': '0xabc', 'currency': 'CHF', 'language': 'EN'});
    });

    test('honours a custom currency', () {
      const dto = SingleReceiptDto(txId: '0xabc', currency: Currency.eur);

      expect(dto.toJson()['currency'], 'EUR');
    });

    test('honours a language override and uppercases the code', () {
      const dto = SingleReceiptDto(txId: '0xabc', language: Language.de);

      expect(dto.toJson()['language'], 'DE');
    });
  });

  group('$PdfDto.fromJson', () {
    test('reads the pdfData field', () {
      final dto = PdfDto.fromJson({'pdfData': 'base64-blob'});

      expect(dto.pdfData, 'base64-blob');
    });
  });

  group('$BalancePdfDto.toJson', () {
    test('defaults language to EN (uppercased on the wire)', () {
      final dto = BalancePdfDto(
        address: '0xwallet',
        currency: Currency.chf,
        date: DateTime.utc(2026, 5, 15),
      );

      expect(dto.toJson(), {
        'address': '0xwallet',
        'currency': 'CHF',
        'date': '2026-05-15T00:00:00.000Z',
        'language': 'EN',
      });
    });

    test('honours a language override and uppercases the code', () {
      final dto = BalancePdfDto(
        address: '0xwallet',
        currency: Currency.eur,
        date: DateTime.utc(2026, 5, 15),
        language: Language.de,
      );

      expect(dto.toJson()['language'], 'DE');
    });
  });

  group('$SupportIssueType', () {
    test('fromJson round-trips known values', () {
      for (final v in SupportIssueType.values) {
        expect(SupportIssueType.fromJson(v.value), v);
      }
    });

    test('fromJson falls back to genericIssue on unknown', () {
      expect(SupportIssueType.fromJson('mystery'), SupportIssueType.genericIssue);
    });

    test('toJson returns the wire value', () {
      expect(SupportIssueType.kycIssue.toJson(), 'KycIssue');
    });
  });

  group('$SupportIssueReason', () {
    test('fromJson round-trips known values', () {
      for (final v in SupportIssueReason.values) {
        expect(SupportIssueReason.fromJson(v.value), v);
      }
    });

    test('fromJson falls back to other on unknown', () {
      expect(SupportIssueReason.fromJson('alien'), SupportIssueReason.other);
    });
  });

  group('$SupportIssueState', () {
    test('fromJson round-trips known values', () {
      for (final v in SupportIssueState.values) {
        expect(SupportIssueState.fromJson(v.value), v);
      }
    });

    test('fromJson falls back to created on unknown', () {
      expect(SupportIssueState.fromJson('weird'), SupportIssueState.created);
    });
  });

  group('$SupportIssueDto.fromJson', () {
    test('parses every field on the happy path', () {
      final dto = SupportIssueDto.fromJson({
        'uid': 'abc-123',
        'state': 'Pending',
        'type': 'KycIssue',
        'reason': 'Other',
        'name': 'KYC stuck',
        'created': '2026-05-15T10:00:00Z',
        'messages': <Map<String, dynamic>>[],
      });

      expect(dto.uid, 'abc-123');
      expect(dto.state, SupportIssueState.pending);
      expect(dto.type, SupportIssueType.kycIssue);
      expect(dto.reason, SupportIssueReason.other);
      expect(dto.messages, isEmpty);
    });

    test('absent messages list defaults to []', () {
      final dto = SupportIssueDto.fromJson({
        'uid': 'abc-123',
        'state': 'Created',
        'type': 'GenericIssue',
        'reason': 'Other',
        'name': 'x',
        'created': '2026-05-15T10:00:00Z',
      });

      expect(dto.messages, isEmpty);
    });
  });

  group('$SupportIssue', () {
    test('isOpen is true for created + pending only', () {
      SupportIssue build(SupportIssueState state) => SupportIssue(
            uid: 'u',
            state: state,
            type: SupportIssueType.genericIssue,
            reason: SupportIssueReason.other,
            name: 'n',
            created: DateTime.utc(2026, 5, 15),
            messages: const [],
          );

      expect(build(SupportIssueState.created).isOpen, isTrue);
      expect(build(SupportIssueState.pending).isOpen, isTrue);
      expect(build(SupportIssueState.completed).isOpen, isFalse);
      expect(build(SupportIssueState.canceled).isOpen, isFalse);
    });

    test('fromDto maps fields and an empty messages list', () {
      final dto = SupportIssueDto(
        uid: 'u',
        state: SupportIssueState.created,
        type: SupportIssueType.genericIssue,
        reason: SupportIssueReason.other,
        name: 'n',
        created: DateTime.utc(2026, 5, 15),
        messages: const [],
      );

      final issue = SupportIssue.fromDto(dto);

      expect(issue.uid, 'u');
      expect(issue.state, SupportIssueState.created);
      expect(issue.messages, isEmpty);
    });
  });

  group('$BankAccount', () {
    test('equality is by id only (Equatable props)', () {
      const a = BankAccount(id: 1, iban: 'CH1', name: 'A');
      const b = BankAccount(id: 1, iban: 'CH2', name: 'B', isActive: true);
      const c = BankAccount(id: 2, iban: 'CH1', name: 'A');

      expect(a, b);
      expect(a, isNot(c));
    });

    test('isActive defaults to false', () {
      const a = BankAccount(id: 1, iban: 'CH1');
      expect(a.isActive, isFalse);
    });
  });

  group('$BuyPaymentInfo', () {
    test('equatable props cover every field', () {
      const a = BuyPaymentInfo(
        amount: 300,
        id: 1,
        iban: 'CH...',
        bic: 'BIC',
        name: 'DFX AG',
        street: 'Bahnhofstrasse',
        number: '1',
        zip: '8000',
        city: 'Zurich',
        country: 'CH',
        currency: Currency.chf,
      );
      const b = BuyPaymentInfo(
        amount: 300,
        id: 1,
        iban: 'CH...',
        bic: 'BIC',
        name: 'DFX AG',
        street: 'Bahnhofstrasse',
        number: '1',
        zip: '8000',
        city: 'Zurich',
        country: 'CH',
        currency: Currency.chf,
      );
      const c = BuyPaymentInfo(
        amount: 300,
        id: 1,
        iban: 'CH...',
        bic: 'BIC',
        name: 'DFX AG',
        street: 'Bahnhofstrasse',
        number: '1',
        zip: '8000',
        city: 'Zurich',
        country: 'CH',
        currency: Currency.eur,
      );

      expect(a, b);
      // Differing currency must break equality.
      expect(a, isNot(c));
    });
  });
}
