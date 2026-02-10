import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/ticket_detail_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../widgets/message_bubble.dart';
import '../../../../shared/components/buttons/app_primary_button.dart';

class TicketDetailScreen extends ConsumerStatefulWidget {
  final int ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  final _messageController = TextEditingController();
  bool _isSending = false;
  bool _isAssigning = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

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
            content: Text('Erro: Não tem permissão para responder a este ticket.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleAssignToMe() async {
    setState(() => _isAssigning = true);
    
    final success = await ref
        .read(ticketDetailControllerProvider(widget.ticketId).notifier)
        .assignToMe();

    if (mounted) {
      setState(() => _isAssigning = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket atribuído com sucesso! Pode responder agora.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao atribuir ticket. Verifique a ligação ou se o ticket já tem dono.'),
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
    final currentUser = authState.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do Ticket')),
      body: ticketState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erro ao carregar: $err')),
        data: (ticket) {
          if (ticket == null) return const Center(child: Text('Ticket não encontrado'));

          final isResolved = ticket.status == 'resolved' || ticket.status == 'closed';
          final isSupporter = currentUser?.isSupporter ?? false;
          final isUnassigned = ticket.assignedTo == null;
          final isAssignedToMe = ticket.assignedTo?.id == currentUser?.id;
          final isMyTicket = ticket.user?.id == currentUser?.id;

          // Regra: Pode responder se não estiver resolvido E (for o dono OU for o técnico atribuído)
          final canReply = !isResolved && (isMyTicket || isAssignedToMe);

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  children: [
                    _buildHeader(ticket),
                    
                    // Banner para Suporte se atribuir
                    if (isSupporter && isUnassigned && !isResolved)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Este ticket precisa de um técnico.',
                                      style: TextStyle(
                                        color: Colors.orange.shade900,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              AppPrimaryButton(
                                text: 'Atribuir a Mim e Responder',
                                isLoading: _isAssigning,
                                onPressed: _handleAssignToMe,
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    const Divider(),
                    _buildUserInfos(ticket),
                    const Divider(),
                    _buildChatSection(ticket, currentUser?.id),
                  ],
                ),
              ),
              _buildInputSection(canReply, isSupporter, isUnassigned, ticket),
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
            title: Text('Técnico responsável: ${ticket.assignedTo!.name}'),
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

  Widget _buildInputSection(bool canReply, bool isSupporter, bool isUnassigned, dynamic ticket) {
    String? blockedMessage;
    
    if (ticket.status == 'resolved' || ticket.status == 'closed') {
      blockedMessage = 'Ticket fechado/resolvido.';
    } else if (!canReply) {
      if (isSupporter && isUnassigned) {
        blockedMessage = 'Atribua o ticket a si para responder.';
      } else if (isSupporter) {
        blockedMessage = 'Ticket pertencente a outro técnico.';
      } else {
        blockedMessage = 'A aguardar ação do suporte.';
      }
    }

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
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    blockedMessage ?? 'Não pode responder.',
                    style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ),
              ),
      ),
    );
  }
}