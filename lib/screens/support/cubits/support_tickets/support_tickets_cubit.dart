import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_support_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_issue.dart';
import 'package:realunit_wallet/screens/support/cubits/support_tickets/support_tickets_state.dart';

class SupportTicketsCubit extends Cubit<SupportTicketsState> {
  final DfxSupportService _supportService;

  SupportTicketsCubit(this._supportService)
    : super(
        const SupportTicketsInitial(),
      ) {
    loadTickets();
  }

  Future<void> loadTickets() async {
    emit(const SupportTicketsLoading());

    try {
      final tickets = await _supportService.getTickets();
      emit(SupportTicketsLoaded(tickets.map(SupportIssue.fromDto).toList()));
    } catch (e) {
      emit(SupportTicketsError(e.toString()));
    }
  }
}
