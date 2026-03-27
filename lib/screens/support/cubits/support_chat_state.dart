import 'package:equatable/equatable.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/dto/support_issue_dto.dart';

sealed class SupportChatState extends Equatable {
  const SupportChatState();

  @override
  List<Object?> get props => [];
}

final class SupportChatInitial extends SupportChatState {
  const SupportChatInitial();
}

final class SupportChatLoading extends SupportChatState {
  const SupportChatLoading();
}

final class SupportChatLoaded extends SupportChatState {
  final SupportIssueDto ticket;
  final bool isSending;

  const SupportChatLoaded({
    required this.ticket,
    this.isSending = false,
  });

  SupportChatLoaded copyWith({
    SupportIssueDto? ticket,
    bool? isSending,
  }) {
    return SupportChatLoaded(
      ticket: ticket ?? this.ticket,
      isSending: isSending ?? this.isSending,
    );
  }

  @override
  List<Object?> get props => [ticket, isSending];
}

final class SupportChatError extends SupportChatState {
  final String message;

  const SupportChatError(this.message);

  @override
  List<Object?> get props => [message];
}
