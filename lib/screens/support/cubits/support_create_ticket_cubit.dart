import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_issue_reason.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_issue_type.dart';
import 'package:realunit_wallet/packages/service/dfx/support_service.dart';
import 'package:realunit_wallet/screens/support/cubits/support_create_ticket_state.dart';

class SupportCreateTicketCubit extends Cubit<SupportCreateTicketState> {
  final SupportService _supportService;

  SupportCreateTicketCubit(this._supportService)
      : super(const SupportCreateTicketState());

  void selectType(SupportIssueType type) {
    emit(state.copyWith(selectedType: type, selectedReason: SupportIssueReason.other));
  }

  void selectReason(SupportIssueReason reason) {
    emit(state.copyWith(selectedReason: reason));
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
