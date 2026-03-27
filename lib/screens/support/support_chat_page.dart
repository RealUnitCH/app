import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/dto/support_message_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/support_service.dart';
import 'package:realunit_wallet/screens/support/cubits/support_chat_cubit.dart';
import 'package:realunit_wallet/screens/support/cubits/support_chat_state.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/styles/colors.dart';

class SupportChatPage extends StatelessWidget {
  final String ticketUid;

  const SupportChatPage({super.key, required this.ticketUid});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SupportChatCubit(getIt<SupportService>(), ticketUid)..loadTicket(),
      child: const _SupportChatView(),
    );
  }
}

class _SupportChatView extends StatefulWidget {
  const _SupportChatView();

  @override
  State<_SupportChatView> createState() => _SupportChatViewState();
}

class _SupportChatViewState extends State<_SupportChatView> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.supportChat),
      ),
      body: BlocConsumer<SupportChatCubit, SupportChatState>(
        listener: (context, state) {
          if (state is SupportChatLoaded) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
          }
        },
        builder: (context, state) {
          return switch (state) {
            SupportChatInitial() || SupportChatLoading() => const Center(
                child: CupertinoActivityIndicator(),
              ),
            SupportChatError(:final message) => Center(
                child: Text(message),
              ),
            SupportChatLoaded(:final ticket, :final isSending) => Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: ticket.messages.length,
                      itemBuilder: (context, index) => _MessageBubble(
                        message: ticket.messages[index],
                      ),
                    ),
                  ),
                  _MessageInput(
                    controller: _messageController,
                    isSending: isSending,
                    isTicketOpen: ticket.isOpen,
                    onSend: () {
                      final message = _messageController.text;
                      if (message.trim().isNotEmpty) {
                        context.read<SupportChatCubit>().sendMessage(message);
                        _messageController.clear();
                      }
                    },
                  ),
                ],
              ),
          };
        },
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final SupportMessageDto message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isFromUser = !message.isFromSupport;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isFromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isFromUser ? RealUnitColors.realUnitBlue : RealUnitColors.neutral100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.message != null)
                  Text(
                    message.message!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isFromUser
                              ? RealUnitColors.basic.white
                              : RealUnitColors.neutral900,
                        ),
                  ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.created),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isFromUser
                            ? RealUnitColors.basic.white.withValues(alpha: 0.7)
                            : RealUnitColors.neutral500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final bool isTicketOpen;
  final VoidCallback onSend;

  const _MessageInput({
    required this.controller,
    required this.isSending,
    required this.isTicketOpen,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    if (!isTicketOpen) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: RealUnitColors.neutral100,
        child: Text(
          'Ticket geschlossen',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: RealUnitColors.neutral500,
              ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RealUnitColors.basic.white,
        border: Border(
          top: BorderSide(color: RealUnitColors.neutral200),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !isSending,
                decoration: InputDecoration(
                  hintText: s.supportEnterMessage,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: RealUnitColors.neutral100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: isSending ? null : onSend,
              icon: isSending
                  ? const CupertinoActivityIndicator()
                  : const Icon(Icons.send, color: RealUnitColors.realUnitBlue),
            ),
          ],
        ),
      ),
    );
  }
}
