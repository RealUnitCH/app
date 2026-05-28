import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/dto/support_message_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_message.dart';

void main() {
  group('$SupportMessageDto.fromJson', () {
    test('parses the full wire shape', () {
      final dto = SupportMessageDto.fromJson({
        'id': 7,
        'author': 'alice',
        'created': '2026-05-15T10:00:00Z',
        'message': 'hi',
        'fileName': 'attachment.pdf',
      });

      expect(dto.id, 7);
      expect(dto.author, 'alice');
      expect(dto.created, DateTime.utc(2026, 5, 15, 10));
      expect(dto.message, 'hi');
      expect(dto.fileName, 'attachment.pdf');
    });

    test('author / message / fileName are all optional (null preserved)', () {
      final dto = SupportMessageDto.fromJson({
        'id': 1,
        'author': null,
        'created': '2026-01-01T00:00:00Z',
        'message': null,
        'fileName': null,
      });

      expect(dto.author, isNull);
      expect(dto.message, isNull);
      expect(dto.fileName, isNull);
    });
  });

  group('$SupportMessage.fromDto', () {
    test('copies every field from the DTO', () {
      final dto = SupportMessageDto.fromJson({
        'id': 7,
        'author': 'alice',
        'created': '2026-05-15T10:00:00Z',
        'message': 'hi',
        'fileName': 'attachment.pdf',
      });

      final msg = SupportMessage.fromDto(dto);

      expect(msg.id, dto.id);
      expect(msg.author, dto.author);
      expect(msg.created, dto.created);
      expect(msg.message, dto.message);
      expect(msg.fileName, dto.fileName);
    });

    // The API constant `CustomerAuthor` is the single value that marks a
    // customer-authored message. Everything else (agent name, AutoResponder,
    // legacy null) renders as support.
    test('isFromCustomer is true for author == "Customer"', () {
      final msg = SupportMessage.fromDto(
        SupportMessageDto(
          id: 1,
          author: 'Customer',
          created: DateTime.utc(2026, 1, 1),
        ),
      );

      expect(msg.isFromCustomer, isTrue);
      expect(msg.isFromSupport, isFalse);
    });

    test('isFromSupport is true for an agent name', () {
      final msg = SupportMessage.fromDto(
        SupportMessageDto(
          id: 1,
          author: 'Robin',
          created: DateTime.utc(2026, 1, 1),
        ),
      );

      expect(msg.isFromCustomer, isFalse);
      expect(msg.isFromSupport, isTrue);
    });

    test('isFromSupport is true for the AutoResponder bot', () {
      final msg = SupportMessage.fromDto(
        SupportMessageDto(
          id: 1,
          author: 'AutoResponder',
          created: DateTime.utc(2026, 1, 1),
        ),
      );

      expect(msg.isFromCustomer, isFalse);
      expect(msg.isFromSupport, isTrue);
    });

    test('isFromSupport is true when author is null (defensive)', () {
      final msg = SupportMessage.fromDto(
        SupportMessageDto(
          id: 1,
          created: DateTime.utc(2026, 1, 1),
        ),
      );

      expect(msg.isFromCustomer, isFalse);
      expect(msg.isFromSupport, isTrue);
    });
  });

  group('$SupportMessage equality (Equatable props)', () {
    // Conversation rendering compares messages to dedupe and to detect
    // edits — the props list must cover every wire field, not just `id`.
    SupportMessage build({
      int id = 1,
      String? author = 'alice',
      DateTime? created,
      String? message = 'hello',
      String? fileName,
    }) {
      return SupportMessage(
        id: id,
        author: author,
        created: created ?? DateTime.utc(2026, 1, 1),
        message: message,
        fileName: fileName,
      );
    }

    test('two messages with identical fields compare equal', () {
      expect(build(), equals(build()));
      expect(build().hashCode, build().hashCode);
    });

    test('each field independently breaks equality when changed', () {
      final base = build();

      expect(base, isNot(equals(build(id: 2))));
      expect(base, isNot(equals(build(author: 'bob'))));
      expect(base, isNot(equals(build(created: DateTime.utc(2026, 2, 1)))));
      expect(base, isNot(equals(build(message: 'other'))));
      expect(base, isNot(equals(build(fileName: 'x.pdf'))));
    });

    test('props exposes [id, author, created, message, fileName] in order', () {
      final created = DateTime.utc(2026, 5, 1);
      final msg = build(
        id: 9,
        author: 'alice',
        created: created,
        message: 'hi',
        fileName: 'a.pdf',
      );

      expect(msg.props, [9, 'alice', created, 'hi', 'a.pdf']);
    });
  });
}
