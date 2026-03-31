import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/styles/colors.dart';

class SupportChatMessageInputField extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final bool isTicketOpen;
  final VoidCallback onSend;

  const SupportChatMessageInputField({
    super.key,
    required this.controller,
    required this.isSending,
    required this.isTicketOpen,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    if (!isTicketOpen) {
      return Container(
        width: .infinity,
        padding: const .all(20),
        color: RealUnitColors.neutral100,
        child: Text(
          S.of(context).supportTicketClosed,
          textAlign: .center,
          style:
              Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(
                color: RealUnitColors.neutral500,
                fontWeight: .w500,
              ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RealUnitColors.basic.white,
        border: const Border(
          top: BorderSide(color: RealUnitColors.neutral200),
        ),
      ),
      child: Row(
        spacing: 8.0,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !isSending,
              decoration: InputDecoration(
                hintText: S.of(context).supportEnterMessage,
                border: OutlineInputBorder(
                  borderRadius: .circular(8.0),
                  borderSide: .none,
                ),
                filled: true,
                fillColor: RealUnitColors.neutral100,
                contentPadding: const .all(12.0),
              ),
              maxLines: null,
            ),
          ),
          IconButton(
            onPressed: isSending ? null : onSend,
            icon: isSending
                ? const CupertinoActivityIndicator()
                : const Icon(Icons.send_rounded, color: RealUnitColors.realUnitBlue),
          ),
        ],
      ),
    );
  }
}
