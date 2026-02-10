import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/ticket_message_model.dart';

class MessageBubble extends StatelessWidget {
  final TicketMessageModel message;
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  Future<void> _openAttachment(BuildContext context) async {
    if (message.attachmentUrl == null) return;

    final uri = Uri.parse(message.attachmentUrl!);
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível abrir o anexo.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Erro ao abrir anexo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = isMe ? Colors.blue.shade600 : Colors.grey.shade200;
    final textColor = isMe ? Colors.white : Colors.black87;
    // O alinhamento interno da coluna: se for eu, alinha à direita (end), senão esquerda (start)
    final align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
      bottomRight: isMe ? Radius.zero : const Radius.circular(16),
    );

    // Envolvemos tudo num Container com width: double.infinity.
    // Isto força o widget a ocupar toda a largura do ecrã, permitindo que
    // o CrossAxisAlignment.end empurre visualmente o conteúdo para a direita.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Column(
        crossAxisAlignment: align,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Text(
                message.user.name,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: borderRadius,
            ),
            constraints: const BoxConstraints(maxWidth: 280),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.attachmentUrl != null)
                  GestureDetector(
                    onTap: () => _openAttachment(context),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.attachment, size: 20, color: Colors.white),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Abrir Anexo",
                              style: TextStyle(
                                color: Colors.white, 
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(Icons.open_in_new, size: 16, color: Colors.white70),
                        ],
                      ),
                    ),
                  ),

                if (message.message.isNotEmpty)
                  Text(
                    message.message,
                    style: TextStyle(color: textColor, fontSize: 15),
                  ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 4, left: 4),
            child: Text(
              message.createdAtHuman,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }
}