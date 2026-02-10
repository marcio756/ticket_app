import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/ticket_detail_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../widgets/message_bubble.dart';

class TicketDetailScreen extends ConsumerStatefulWidget {
  final int ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  final _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  /// Handles the message submission logic.
  Future<void> _handleSendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    
    final success = await ref
        .read(ticketDetailControllerProvider(widget.ticketId).notifier)
        .addMessage(text);

    if (mounted) {
      setState(() => _isSending = false);
      if (success) {
        _messageController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro: Não tem permissão para responder a este ticket ou o ticket está fechado.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketState = ref.watch(ticketDetailControllerProvider(widget.ticketId));
    final authState = ref.watch(authControllerProvider);
    final currentUserId = authState.user?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do Ticket')),
      body: ticketState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erro ao carregar dados: $err')),
        data: (ticket) {
          if (ticket == null) return const Center(child: Text('Ticket não encontrado'));

          // Logic: Only allow replies if ticket is not resolved or closed
          final canReply = ticket.status != 'resolved' && ticket.status != 'closed';

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  children: [
                    _buildHeader(ticket),
                    const Divider(),
                    _buildUserInfos(ticket),
                    const Divider(),
                    _buildChatSection(ticket, currentUserId),
                  ],
                ),
              ),
              _buildInputSection(canReply),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(dynamic ticket) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ticket.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Chip(
                label: Text(ticket.statusLabel),
                backgroundColor: ticket.statusColor.withOpacity(0.2),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text(ticket.priority.toUpperCase()),
                backgroundColor: ticket.priorityColor.withOpacity(0.2),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Descrição:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(ticket.description),
        ],
      ),
    );
  }

  Widget _buildUserInfos(dynamic ticket) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: Text('Criado por: ${ticket.user?.name ?? "Desconhecido"}'),
          subtitle: Text(ticket.user?.email ?? ""),
        ),
        if (ticket.assignedTo != null)
          ListTile(
            leading: const Icon(Icons.support_agent),
            title: Text('Técnico atribuído: ${ticket.assignedTo!.name}'),
            subtitle: Text(ticket.assignedTo!.email),
          ),
      ],
    );
  }

  Widget _buildChatSection(dynamic ticket, int? currentUserId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Mensagens (${ticket.messages.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (ticket.messages.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('Ainda não existem mensagens.', style: TextStyle(color: Colors.grey))),
          )
        else
          ...ticket.messages.map((msg) => MessageBubble(
                message: msg,
                isMe: msg.user.id == currentUserId,
              )),
      ],
    );
  }

  Widget _buildInputSection(bool canReply) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black.withOpacity(0.1))],
      ),
      child: SafeArea(
        child: canReply
            ? Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Escrever mensagem...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isSending
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : IconButton(
                          icon: const Icon(Icons.send, color: Colors.blue),
                          onPressed: _handleSendMessage,
                        ),
                ],
              )
            : const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Ticket finalizado. Não é possível enviar novas mensagens.',
                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ),
              ),
      ),
    );
  }
}