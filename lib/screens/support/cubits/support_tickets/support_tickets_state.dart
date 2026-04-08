import 'package:equatable/equatable.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_issue.dart';

sealed class SupportTicketsState extends Equatable {
  const SupportTicketsState();

  @override
  List<Object?> get props => [];
}

final class SupportTicketsInitial extends SupportTicketsState {
  const SupportTicketsInitial();
}

final class SupportTicketsLoading extends SupportTicketsState {
  const SupportTicketsLoading();
}

final class SupportTicketsLoaded extends SupportTicketsState {
  final List<SupportIssue> tickets;

  const SupportTicketsLoaded(this.tickets);

  @override
  List<Object?> get props => [tickets];
}

final class SupportTicketsError extends SupportTicketsState {
  final String message;

  const SupportTicketsError(this.message);

  @override
  List<Object?> get props => [message];
}
