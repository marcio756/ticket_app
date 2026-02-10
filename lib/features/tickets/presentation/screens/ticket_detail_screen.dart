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
      appBar: AppBar(
        title: const Text('Detalhes do Ticket'),
        elevation: 0,
      ),
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

          final canReply = !isResolved && (isMyTicket || isAssignedToMe);

          return Column(
            children: [
              // 1. CABEÇALHO FIXO (Não faz scroll com as mensagens)
              _buildCollapsibleHeader(ticket),

              // 2. ÁREA DE SCROLL (Apenas para mensagens e avisos)
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    // Banner de Suporte
                    if (isSupporter && isUnassigned && !isResolved)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
                    
                    // Lista de Mensagens
                    _buildChatSection(ticket, currentUser?.id),
                  ],
                ),
              ),

              // 3. INPUT (Fixo no fundo)
              _buildInputSection(canReply, isSupporter, isUnassigned, ticket),
            ],
          );
        },
      ),
    );
  }

  /// O cabeçalho agora está desenhado para ficar fixo no topo.
  Widget _buildCollapsibleHeader(dynamic ticket) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            // CORRIGIDO: withOpacity -> withValues
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        initiallyExpanded: true, 
        // CORRIGIDO: Removido o callback onExpansionChanged e a variável _isHeaderExpanded
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: const Border(), 
        
        // TÍTULO (Sempre visível)
        title: Text(
          ticket.title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: ticket.statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              ticket.formattedDate,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
        
        // CONTEÚDO (Escondido ao minimizar)
        children: [
          const Divider(),
          const SizedBox(height: 8),
          
          Row(
            children: [
              Chip(
                label: Text(ticket.statusLabel),
                // CORRIGIDO: withOpacity -> withValues
                backgroundColor: ticket.statusColor.withValues(alpha: 0.1),
                labelStyle: TextStyle(color: ticket.statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text('Prioridade ${ticket.priority.toUpperCase()}'),
                // CORRIGIDO: withOpacity -> withValues
                backgroundColor: ticket.priorityColor.withValues(alpha: 0.1),
                labelStyle: TextStyle(color: ticket.priorityColor, fontSize: 12, fontWeight: FontWeight.bold),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Descrição
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Descrição:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  ticket.description,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          _buildUserInfos(ticket),
        ],
      ),
    );
  }

  Widget _buildUserInfos(dynamic ticket) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          leading: const Icon(Icons.person_outline, size: 20),
          title: Text(ticket.user?.name ?? "Desconhecido", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          subtitle: Text(ticket.user?.email ?? "", style: const TextStyle(fontSize: 12)),
        ),
        if (ticket.assignedTo != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: const Icon(Icons.support_agent, size: 20, color: Colors.blue),
            title: Text(ticket.assignedTo!.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: Text('Técnico Responsável', style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
          ),
      ],
    );
  }

  Widget _buildChatSection(dynamic ticket, int? currentUserId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            children: [
              const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                'Mensagens (${ticket.messages.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  fontSize: 14
                ),
              ),
            ],
          ),
        ),
        if (ticket.messages.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text('Ainda não existem mensagens.', style: TextStyle(color: Colors.grey)),
            ),
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
        blockedMessage = 'Necessário atribuir ticket.';
      } else if (isSupporter) {
        blockedMessage = 'Ticket de outro técnico.';
      } else {
        blockedMessage = 'A aguardar suporte.';
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
            // CORRIGIDO: withOpacity -> withValues
            BoxShadow(blurRadius: 4, color: Colors.black.withValues(alpha: 0.05))
        ],
        border: const Border(top: BorderSide(color: Colors.black12)),
      ),
      child: SafeArea(
        child: canReply
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Escrever mensagem...',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      maxLines: 4,
                      minLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: _isSending
                      ? const Padding(
                          padding: EdgeInsets.all(10.0),
                          child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                        )
                      : IconButton(
                          icon: const Icon(Icons.send, color: Colors.white, size: 20),
                          onPressed: _handleSendMessage,
                        ),
                  ),
                ],
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        blockedMessage ?? 'Não pode responder.',
                        style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}