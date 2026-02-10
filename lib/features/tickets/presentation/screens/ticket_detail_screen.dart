import 'dart:async'; // [IMPORTANTE] Necessário para o Timer
import 'dart:io'; 
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
  
  // Estado local para anexo
  File? _selectedAttachment;
  
  // Estados de carregamento
  bool _isSending = false;
  bool _isAssigning = false;

  // [NOVO] Timer para contar o tempo de suporte automaticamente
  Timer? _trackingTimer;
  // Intervalo de 30 segundos para o "heartbeat"
  static const int _trackingIntervalSeconds = 30;

  @override
  void initState() {
    super.initState();
    // Inicia o tracking após o widget ser montado para ter acesso seguro ao ref
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSupportTracking();
    });
  }

  @override
  void dispose() {
    _trackingTimer?.cancel(); // [CRÍTICO] Cancelar timer ao sair do ecrã
    _messageController.dispose();
    super.dispose();
  }

  /// Inicia o contador se o utilizador for Staff
  void _startSupportTracking() {
    final authState = ref.read(authControllerProvider);
    final user = authState.user;
    
    // Apenas Staff (Admin/Support) consome tempo do cliente
    if (user != null && user.isSupporter) {
      // Cria um timer repetitivo
      _trackingTimer = Timer.periodic(
        const Duration(seconds: _trackingIntervalSeconds), 
        (timer) {
          // Verifica se o widget ainda está na árvore
          if (!mounted) {
             timer.cancel();
             return;
          }

          // Chama o controller para enviar o "ping" à API
          // Isto vai descontar 30s do saldo do cliente
          ref.read(ticketDetailControllerProvider(widget.ticketId).notifier)
             .trackTime(); // Certifica-te que este método existe no controller
      });
    }
  }

  Future<void> _handlePickAttachment() async {
    final file = await ref
        .read(ticketDetailControllerProvider(widget.ticketId).notifier)
        .pickAttachment();

    if (file != null) {
      setState(() {
        _selectedAttachment = file;
      });
    }
  }

  void _removeAttachment() {
    setState(() {
      _selectedAttachment = null;
    });
  }

  Future<void> _handleSendMessage() async {
    final text = _messageController.text.trim();
    if ((text.isEmpty && _selectedAttachment == null) || _isSending) return;

    setState(() => _isSending = true);
    
    final success = await ref
        .read(ticketDetailControllerProvider(widget.ticketId).notifier)
        .addMessage(text, attachment: _selectedAttachment);

    if (mounted) {
      setState(() => _isSending = false);
      if (success) {
        _messageController.clear();
        _selectedAttachment = null;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro: Não foi possível enviar. Verifique o tempo de suporte.'),
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
          const SnackBar(content: Text('Ticket atribuído com sucesso!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao atribuir ticket.'),
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
          final isAssignedToMe = ticket.assignedTo?.id == currentUser?.id;
          final isMyTicket = ticket.user?.id == currentUser?.id;
          final isUnassigned = ticket.assignedTo == null;

          // LOGICA DE BLOQUEIO DE TEMPO:
          final ticketOwner = ticket.user;
          // Se owner for null, assume 0 para segurança
          final ownerHasTime = (ticketOwner?.dailySupportSeconds ?? 0) > 0;

          // Se não houver tempo, bloqueia tudo
          final isTimeBlocked = !ownerHasTime;

          // Permissão para responder
          final canReply = !isResolved && (isMyTicket || isAssignedToMe) && !isTimeBlocked;

          return Column(
            children: [
              // 1. CABEÇALHO (Com badge de tempo)
              _buildCollapsibleHeader(ticket, ownerHasTime),

              // 2. CONTEÚDO SCROLLÁVEL
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    // Aviso Vermelho se acabou o tempo
                    if (isTimeBlocked && !isResolved)
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.timer_off_outlined, color: Colors.red.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isSupporter 
                                  ? 'Cliente sem tempo de suporte restante. Respostas bloqueadas.'
                                  : 'Esgotou o seu tempo diário (30min). Tente novamente amanhã.',
                                style: TextStyle(color: Colors.red.shade900, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Botão para atribuir ticket (apenas staff e se ticket livre)
                    if (isSupporter && isUnassigned && !isResolved && !isTimeBlocked)
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
                    
                    _buildChatSection(ticket, currentUser?.id),
                  ],
                ),
              ),

              // 3. INPUT (Bloqueado se isTimeBlocked for true)
              _buildInputSection(canReply, isSupporter, isUnassigned, isTimeBlocked, ticket),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCollapsibleHeader(dynamic ticket, bool ownerHasTime) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        initiallyExpanded: true, 
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: const Border(), 
        
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
            const Spacer(),
            // Badge visual do Tempo Restante
            if (ticket.user != null)
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                 decoration: BoxDecoration(
                   color: ownerHasTime ? Colors.green.shade50 : Colors.red.shade50,
                   borderRadius: BorderRadius.circular(12),
                   border: Border.all(color: ownerHasTime ? Colors.green.shade200 : Colors.red.shade200),
                 ),
                 child: Row(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     Icon(
                       Icons.timer, 
                       size: 12, 
                       color: ownerHasTime ? Colors.green.shade700 : Colors.red.shade700
                     ),
                     const SizedBox(width: 4),
                     Text(
                       ticket.user!.formattedSupportTime,
                       style: TextStyle(
                         fontSize: 10, 
                         fontWeight: FontWeight.bold,
                         color: ownerHasTime ? Colors.green.shade800 : Colors.red.shade800
                       ),
                     ),
                   ],
                 ),
               ),
          ],
        ),
        children: [
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              Chip(
                label: Text(ticket.statusLabel),
                backgroundColor: ticket.statusColor.withOpacity(0.1),
                labelStyle: TextStyle(color: ticket.statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text('Prioridade ${ticket.priority.toUpperCase()}'),
                backgroundColor: ticket.priorityColor.withOpacity(0.1),
                labelStyle: TextStyle(color: ticket.priorityColor, fontSize: 12, fontWeight: FontWeight.bold),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 12),
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

  Widget _buildInputSection(
    bool canReply, 
    bool isSupporter, 
    bool isUnassigned, 
    bool isTimeBlocked,
    dynamic ticket
  ) {
    String? blockedMessage;
    
    if (ticket.status == 'resolved' || ticket.status == 'closed') {
      blockedMessage = 'Ticket fechado/resolvido.';
    } else if (isTimeBlocked) {
      blockedMessage = 'Tempo de suporte diário esgotado.';
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
            BoxShadow(blurRadius: 4, color: Colors.black.withValues(alpha: 0.05))
        ],
        border: const Border(top: BorderSide(color: Colors.black12)),
      ),
      child: SafeArea(
        child: canReply
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PREVIEW DE ANEXO
                  if (_selectedAttachment != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.attach_file, size: 20, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedAttachment!.path.split('/').last,
                              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          InkWell(
                            onTap: _removeAttachment,
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(Icons.close, size: 18, color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ÁREA DE TEXTO E BOTÕES
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 8, bottom: 4),
                        child: IconButton(
                          icon: Icon(Icons.attach_file, color: Colors.grey.shade600),
                          onPressed: _handlePickAttachment,
                          tooltip: 'Anexar Ficheiro',
                        ),
                      ),
                      
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: _selectedAttachment != null ? 'Adicionar comentário...' : 'Escrever mensagem...',
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
                  ),
                ],
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isTimeBlocked ? Icons.timer_off_outlined : Icons.lock_outline, 
                        size: 16, 
                        color: isTimeBlocked ? Colors.red : Colors.grey
                      ),
                      const SizedBox(width: 8),
                      Text(
                        blockedMessage ?? 'Não pode responder.',
                        style: TextStyle(
                          color: isTimeBlocked ? Colors.red : Colors.grey, 
                          fontStyle: FontStyle.italic,
                          fontWeight: isTimeBlocked ? FontWeight.bold : FontWeight.normal
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}