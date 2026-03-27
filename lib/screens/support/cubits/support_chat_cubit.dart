import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/support_service.dart';
import 'package:realunit_wallet/screens/support/cubits/support_chat_state.dart';

class SupportChatCubit extends Cubit<SupportChatState> {
  final SupportService _supportService;
  final String ticketUid;

  SupportChatCubit(this._supportService, this.ticketUid)
      : super(const SupportChatInitial());

  Future<void> loadTicket() async {
    emit(const SupportChatLoading());

    try {
      final ticket = await _supportService.getTicket(ticketUid);
      emit(SupportChatLoaded(ticket: ticket));
    } catch (e) {
      emit(SupportChatError(e.toString()));
    }
  }

  Future<void> sendMessage(String message) async {
    final currentState = state;
    if (currentState is! SupportChatLoaded || message.trim().isEmpty) return;

    emit(currentState.copyWith(isSending: true));

    try {
      await _supportService.sendMessage(ticketUid, message);
      final ticket = await _supportService.getTicket(ticketUid);
      emit(SupportChatLoaded(ticket: ticket));
    } catch (e) {
      emit(currentState.copyWith(isSending: false));
    }
  }
}
