import 'package:equatable/equatable.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/dto/support_message_dto.dart';

// Mirrors the API constant in `support-message.entity.ts`. Customer-authored
// messages carry this exact author value; anything else (agent name,
// `AutoResponder`, …) is rendered as support.
const String customerAuthor = 'Customer';

class SupportMessage extends Equatable {
  final int id;
  final String? author;
  final DateTime created;
  final String? message;
  final String? fileName;

  const SupportMessage({
    required this.id,
    this.author,
    required this.created,
    this.message,
    this.fileName,
  });

  bool get isFromCustomer => author == customerAuthor;
  bool get isFromSupport => !isFromCustomer;

  factory SupportMessage.fromDto(SupportMessageDto dto) {
    return SupportMessage(
      id: dto.id,
      author: dto.author,
      created: dto.created,
      message: dto.message,
      fileName: dto.fileName,
    );
  }

  @override
  List<Object?> get props => [id, author, created, message, fileName];
}
