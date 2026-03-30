import 'package:equatable/equatable.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/dto/support_issue_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_issue_reason.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_issue_state.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_issue_type.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_message.dart';

class SupportIssue extends Equatable {
  final String uid;
  final SupportIssueState state;
  final SupportIssueType type;
  final SupportIssueReason reason;
  final String name;
  final DateTime created;
  final List<SupportMessage> messages;

  const SupportIssue({
    required this.uid,
    required this.state,
    required this.type,
    required this.reason,
    required this.name,
    required this.created,
    required this.messages,
  });

  bool get isOpen => state == SupportIssueState.created || state == SupportIssueState.pending;

  factory SupportIssue.fromDto(SupportIssueDto dto) {
    return SupportIssue(
      uid: dto.uid,
      state: dto.state,
      type: dto.type,
      reason: dto.reason,
      name: dto.name,
      created: dto.created,
      messages: dto.messages.map(SupportMessage.fromDto).toList(),
    );
  }

  @override
  List<Object?> get props => [uid, state, type, reason, name, created, messages];
}
