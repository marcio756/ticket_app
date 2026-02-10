import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/ticket_detail_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../widgets/ticket_detail_header.dart';
import '../widgets/ticket_status_banner.dart';
import '../widgets/ticket_message_list.dart';
import '../widgets/ticket_input_area.dart';

class TicketDetailScreen extends ConsumerStatefulWidget {
  final int ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  // Loading states
  bool _isSending = false;
  bool _isAssigning = false;

  // Support timer logic
  Timer? _trackingTimer;
  static const int _trackingIntervalSeconds = 30;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSupportTracking();
    });
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    super.dispose();
  }

  /// Starts the support tracking timer if the user is a supporter.
  void _startSupportTracking() {
    final authState = ref.read(authControllerProvider);
    final user = authState.user;

    if (user != null && user.isSupporter) {
      _trackingTimer = Timer.periodic(
          const Duration(seconds: _trackingIntervalSeconds), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        ref
            .read(ticketDetailControllerProvider(widget.ticketId).notifier)
            .trackTime();
      });
    }
  }

  /// Handles sending a new message.
  Future<void> _handleSendMessage(String text, File? attachment) async {
    final cleanText = text.trim();
    if ((cleanText.isEmpty && attachment == null) || _isSending) return;

    setState(() => _isSending = true);

    final success = await ref
        .read(ticketDetailControllerProvider(widget.ticketId).notifier)
        .addMessage(cleanText, attachment: attachment);

    if (mounted) {
      setState(() => _isSending = false);
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Erro: Não foi possível enviar. Verifique o tempo de suporte.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handles assigning the ticket to the current user.
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
    final ticketState =
        ref.watch(ticketDetailControllerProvider(widget.ticketId));
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
          if (ticket == null) {
            return const Center(child: Text('Ticket não encontrado'));
          }

          // Business Logic: Check if time is blocked
          final ticketOwner = ticket.user;
          final ownerHasTime = (ticketOwner?.dailySupportSeconds ?? 0) > 0;
          final isTimeBlocked = !ownerHasTime;

          return Column(
            children: [
              // 1. Ticket Header Information
              TicketDetailHeader(ticket: ticket),

              // 2. Scrollable Content (Messages & Status Banners)
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    TicketStatusBanner(
                      ticket: ticket,
                      currentUser: currentUser,
                      isTimeBlocked: isTimeBlocked,
                      isAssigning: _isAssigning,
                      onAssignTap: _handleAssignToMe,
                    ),
                    TicketMessageList(
                      messages: ticket.messages,
                      currentUserId: currentUser?.id,
                    ),
                  ],
                ),
              ),

              // 3. Input Area
              TicketInputArea(
                ticket: ticket,
                currentUser: currentUser,
                isTimeBlocked: isTimeBlocked,
                isSending: _isSending,
                onSendMessage: _handleSendMessage,
              ),
            ],
          );
        },
      ),
    );
  }
}