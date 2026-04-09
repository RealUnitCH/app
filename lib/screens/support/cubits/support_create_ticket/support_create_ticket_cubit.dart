import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_support_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_issue_reason.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_issue_type.dart';
import 'package:realunit_wallet/screens/support/cubits/support_create_ticket/support_create_ticket_state.dart';

class SupportCreateTicketCubit extends Cubit<SupportCreateTicketState> {
  final DfxSupportService _supportService;

  SupportCreateTicketCubit(DfxSupportService supportService)
    : _supportService = supportService,
      super(const SupportCreateTicketState());

  void selectType(SupportIssueType type) {
    emit(state.copyWith(selectedType: type, selectedReason: SupportIssueReason.other));
  }

  void updateMessage(String message) {
    emit(state.copyWith(message: message));
  }

  Future<void> submit() async {
    if (!state.canSubmit) return;

    emit(state.copyWith(isSubmitting: true, error: null));

    try {
      await _supportService.createTicket(
        type: state.selectedType!,
        reason: state.selectedReason!,
        name: _getTicketName(state.selectedType!),
        message: state.message,
      );

      emit(state.copyWith(isSubmitting: false, isSuccess: true));
    } catch (e) {
      developer.log('Could not create ticket: $e', name: '$SupportCreateTicketCubit');
      emit(state.copyWith(isSubmitting: false, error: e.toString()));
    }
  }

  String _getTicketName(SupportIssueType type) {
    return switch (type) {
      SupportIssueType.genericIssue => 'General Issue',
      SupportIssueType.transactionIssue => 'Transaction Issue',
      SupportIssueType.kycIssue => 'KYC Issue',
      SupportIssueType.limitRequest => 'Limit Request',
      SupportIssueType.bugReport => 'Bug Report',
      _ => 'Support Request',
    };
  }
}
