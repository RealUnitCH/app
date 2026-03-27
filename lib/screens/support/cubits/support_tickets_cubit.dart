import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/support_service.dart';
import 'package:realunit_wallet/screens/support/cubits/support_tickets_state.dart';

class SupportTicketsCubit extends Cubit<SupportTicketsState> {
  final SupportService _supportService;

  SupportTicketsCubit(this._supportService) : super(const SupportTicketsInitial());

  Future<void> loadTickets() async {
    emit(const SupportTicketsLoading());

    try {
      final tickets = await _supportService.getTickets();
      emit(SupportTicketsLoaded(tickets));
    } catch (e) {
      emit(SupportTicketsError(e.toString()));
    }
  }
}
