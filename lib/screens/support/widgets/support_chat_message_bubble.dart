import 'package:flutter/material.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_message.dart';
import 'package:realunit_wallet/styles/colors.dart';

class SupportChatMessageBubble extends StatelessWidget {
  final SupportMessage supportMessage;

  const SupportChatMessageBubble({
    super.key,
    required this.supportMessage,
  });

  @override
  Widget build(BuildContext context) {
    final isFromUser = !supportMessage.isFromSupport;

    return Padding(
      padding: const .symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isFromUser ? .end : .start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const .symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isFromUser ? RealUnitColors.realUnitBlue : RealUnitColors.neutral100,
              borderRadius: .circular(12),
            ),
            child: Column(
              crossAxisAlignment: isFromUser ? .end : .start,
              spacing: 4.0,
              children: [
                if (supportMessage.message != null)
                  Text(
                    supportMessage.message!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isFromUser ? RealUnitColors.basic.white : RealUnitColors.neutral900,
                    ),
                  ),
                Text(
                  _formatTime(supportMessage.created),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isFromUser ? RealUnitColors.neutral300 : RealUnitColors.neutral500,
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
    final offset = DateTime.now().timeZoneOffset;
    final adjustedDateToTimezone = date.add(offset);
    return '${adjustedDateToTimezone.hour.toString().padLeft(2, '0')}:${adjustedDateToTimezone.minute.toString().padLeft(2, '0')}';
  }
}
