import 'package:flutter/material.dart';
import '../../data/models/ticket_message_model.dart';
import 'message_bubble.dart';

/// Renders the list of messages or a placeholder if empty.
class TicketMessageList extends StatelessWidget {
  final List<TicketMessageModel> messages;
  final int? currentUserId;

  const TicketMessageList({
    super.key,
    required this.messages,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            children: [
              const Icon(Icons.chat_bubble_outline,
                  size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                'Mensagens (${messages.length})',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    fontSize: 14),
              ),
            ],
          ),
        ),
        if (messages.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text('Ainda não existem mensagens.',
                  style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          ...messages.map((msg) => MessageBubble(
                message: msg,
                isMe: msg.user.id == currentUserId,
              )),
      ],
    );
  }
}