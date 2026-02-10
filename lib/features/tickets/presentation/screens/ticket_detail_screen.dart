import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/ticket_detail_controller.dart';
import '../widgets/message_bubble.dart';

class TicketDetailScreen extends HookConsumerWidget {
  final int ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(ticketDetailControllerProvider(ticketId));
    final notifier = ref.read(ticketDetailControllerProvider(ticketId).notifier);
    final currentUser = ref.watch(authControllerProvider).user;
    
    final textController = useTextEditingController();
    final scrollController = useScrollController();

    useEffect(() {
      if (controller.ticket.hasValue) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (scrollController.hasClients) {
            scrollController.jumpTo(scrollController.position.maxScrollExtent);
          }
        });
      }
      return null;
    }, [controller.ticket.valueOrNull]);

    return Scaffold(
      appBar: AppBar(
        title: Text('Ticket #$ticketId'),
      ),
      body: Column(
        children: [
          Expanded(
            child: controller.ticket.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Erro: $err')),
              data: (ticket) {
                final messages = ticket.messages;

                if (messages.isEmpty) {
                  return const Center(child: Text('Sem mensagens. Comece a conversa!'));
                }

                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return MessageBubble(
                      message: msg,
                      isMe: currentUser?.id == msg.user.id,
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  if (controller.selectedAttachment != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.attach_file, size: 20, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              controller.selectedAttachment!.path.split('/').last,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: notifier.clearAttachment,
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.attach_file),
                        color: Colors.grey.shade600,
                        onPressed: notifier.pickAttachment,
                      ),
                      Expanded(
                        child: TextField(
                          controller: textController,
                          decoration: const InputDecoration(
                            hintText: 'Escreva uma mensagem...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8),
                          ),
                          minLines: 1,
                          maxLines: 4,
                        ),
                      ),
                      IconButton(
                        icon: controller.isSending 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.send),
                        color: Colors.blue,
                        onPressed: controller.isSending ? null : () async {
                          // Fecha o teclado para ver o feedback melhor
                          FocusScope.of(context).unfocus();
                          
                          final success = await notifier.sendMessage(textController.text);
                          
                          if (success) {
                            textController.clear();
                          } else {
                            // Se falhar, mostra aviso
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Falha ao enviar mensagem. Tente novamente.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}