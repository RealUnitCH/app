import 'package:realunit_wallet/packages/service/dfx/models/support/dto/support_message_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_issue_reason.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_issue_state.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_issue_type.dart';

class SupportIssueDto {
  final String uid;
  final SupportIssueState state;
  final SupportIssueType type;
  final SupportIssueReason reason;
  final String name;
  final DateTime created;
  final List<SupportMessageDto> messages;

  const SupportIssueDto({
    required this.uid,
    required this.state,
    required this.type,
    required this.reason,
    required this.name,
    required this.created,
    required this.messages,
  });

  factory SupportIssueDto.fromJson(Map<String, dynamic> json) {
    return SupportIssueDto(
      uid: json['uid'] as String,
      state: SupportIssueState.fromJson(json['state'] as String),
      type: SupportIssueType.fromJson(json['type'] as String),
      reason: SupportIssueReason.fromJson(json['reason'] as String),
      name: json['name'] as String,
      created: DateTime.parse(json['created'] as String),
      messages: (json['messages'] as List<dynamic>?)
              ?.map((e) => SupportMessageDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

}
