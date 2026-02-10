import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/models/ticket_model.dart';
import '../../../auth/data/models/user_model.dart';

/// Handles message input, file attachments, and send logic.
class TicketInputArea extends StatefulWidget {
  final TicketModel ticket;
  final UserModel? currentUser;
  final bool isTimeBlocked;
  final bool isSending;
  final Function(String text, File? attachment) onSendMessage;

  const TicketInputArea({
    super.key,
    required this.ticket,
    required this.currentUser,
    required this.isTimeBlocked,
    required this.isSending,
    required this.onSendMessage,
  });

  @override
  State<TicketInputArea> createState() => _TicketInputAreaState();
}

class _TicketInputAreaState extends State<TicketInputArea> {
  final _messageController = TextEditingController();
  File? _selectedAttachment;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _handlePickAttachment() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedAttachment = File(result.files.single.path!);
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  void _removeAttachment() {
    setState(() {
      _selectedAttachment = null;
    });
  }

  void _onSendPressed() {
    widget.onSendMessage(_messageController.text, _selectedAttachment);
    // Clear input on parent success handled by parent re-render or explicit callback?
    // Since parent handles async, we clear here optimistically or wait. 
    // Ideally we should wait, but for simplicity we clear here if not handling error feedback inside component
    if (!widget.isSending) {
         _messageController.clear();
         _selectedAttachment = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isResolved = widget.ticket.status == 'resolved' || widget.ticket.status == 'closed';
    final isSupporter = widget.currentUser?.isSupporter ?? false;
    final isAssignedToMe = widget.ticket.assignedTo?.id == widget.currentUser?.id;
    final isMyTicket = widget.ticket.user?.id == widget.currentUser?.id;
    final isUnassigned = widget.ticket.assignedTo == null;

    // Logic to determine if user can reply
    final canReply = !isResolved &&
        (isMyTicket || isAssignedToMe) &&
        !widget.isTimeBlocked;

    String? blockedMessage;

    if (isResolved) {
      blockedMessage = 'Ticket fechado/resolvido.';
    } else if (widget.isTimeBlocked) {
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
          BoxShadow(
              blurRadius: 4, color: Colors.black.withValues(alpha: 0.05))
        ],
        border: const Border(top: BorderSide(color: Colors.black12)),
      ),
      child: SafeArea(
        child: canReply
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Attachment Preview
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
                          const Icon(Icons.attach_file,
                              size: 20, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedAttachment!.path.split('/').last,
                              style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          InkWell(
                            onTap: _removeAttachment,
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(Icons.close,
                                  size: 18, color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Text Area and Buttons
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 8, bottom: 4),
                        child: IconButton(
                          icon: Icon(Icons.attach_file,
                              color: Colors.grey.shade600),
                          onPressed: _handlePickAttachment,
                          tooltip: 'Anexar Ficheiro',
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: _selectedAttachment != null
                                ? 'Adicionar comentário...'
                                : 'Escrever mensagem...',
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
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
                        child: widget.isSending
                            ? const Padding(
                                padding: EdgeInsets.all(10.0),
                                child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2)),
                              )
                            : IconButton(
                                icon: const Icon(Icons.send,
                                    color: Colors.white, size: 20),
                                onPressed: _onSendPressed,
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
                          widget.isTimeBlocked
                              ? Icons.timer_off_outlined
                              : Icons.lock_outline,
                          size: 16,
                          color: widget.isTimeBlocked
                              ? Colors.red
                              : Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        blockedMessage ?? 'Não pode responder.',
                        style: TextStyle(
                            color: widget.isTimeBlocked
                                ? Colors.red
                                : Colors.grey,
                            fontStyle: FontStyle.italic,
                            fontWeight: widget.isTimeBlocked
                                ? FontWeight.bold
                                : FontWeight.normal),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}