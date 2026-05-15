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

    test('isFromSupport is true when author is null', () {
      final msg = SupportMessage.fromDto(
        SupportMessageDto(
          id: 1,
          created: DateTime.utc(2026, 1, 1),
          // author absent → from support (server side)
        ),
      );

      expect(msg.isFromSupport, isTrue);
    });

    test('isFromSupport is false when author is set', () {
      final msg = SupportMessage.fromDto(
        SupportMessageDto(
          id: 1,
          author: 'alice',
          created: DateTime.utc(2026, 1, 1),
        ),
      );

      expect(msg.isFromSupport, isFalse);
    });
  });
}
