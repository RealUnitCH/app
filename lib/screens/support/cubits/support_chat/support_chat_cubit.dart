import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_support_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_issue.dart';
import 'package:realunit_wallet/screens/support/cubits/support_chat/support_chat_state.dart';

class SupportChatCubit extends Cubit<SupportChatState> {
  final DfxSupportService _supportService;
  final String _ticketUid;

  SupportChatCubit(DfxSupportService supportService, String ticketUid)
    : _supportService = supportService,
      _ticketUid = ticketUid,
      super(const SupportChatInitial()) {
    loadTicket();
  }

  Future<void> loadTicket() async {
    emit(const SupportChatLoading());

    try {
      final ticket = await _supportService.getTicket(_ticketUid);
      emit(SupportChatLoaded(ticket: SupportIssue.fromDto(ticket)));
    } catch (e) {
      developer.log('Could not load ticket: $e', name: '$SupportChatCubit');
      emit(SupportChatError(e.toString()));
    }
  }

  Future<void> sendMessage(String message) async {
    final currentState = state;
    if (currentState is! SupportChatLoaded || message.trim().isEmpty) return;

    emit(currentState.copyWith(isSending: true));

    try {
      await _supportService.sendMessage(_ticketUid, message);
      final ticket = await _supportService.getTicket(_ticketUid);
      emit(SupportChatLoaded(ticket: SupportIssue.fromDto(ticket)));
    } catch (e) {
      developer.log('Could not send message: $e', name: '$SupportChatCubit');
      emit(currentState.copyWith(isSending: false));
    }
  }
}
