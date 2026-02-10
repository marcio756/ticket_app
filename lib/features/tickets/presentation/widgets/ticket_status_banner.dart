import 'package:flutter/material.dart';
import '../../data/models/ticket_model.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../../shared/components/buttons/app_primary_button.dart';

/// Displays warning banners (e.g., Time Blocked) or action banners (e.g., Assign to Me).
class TicketStatusBanner extends StatelessWidget {
  final TicketModel ticket;
  final UserModel? currentUser;
  final bool isTimeBlocked;
  final bool isAssigning;
  final VoidCallback onAssignTap;

  const TicketStatusBanner({
    super.key,
    required this.ticket,
    required this.currentUser,
    required this.isTimeBlocked,
    required this.isAssigning,
    required this.onAssignTap,
  });

  @override
  Widget build(BuildContext context) {
    final isResolved = ticket.status == 'resolved' || ticket.status == 'closed';
    final isUnassigned = ticket.assignedTo == null;
    final isSupporter = currentUser?.isSupporter ?? false;

    return Column(
      children: [
        // Red Warning if time is up
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
                    style: TextStyle(
                        color: Colors.red.shade900,
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

        // Assign to Me Action Button (Staff only)
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
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.orange.shade800),
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
                    isLoading: isAssigning,
                    onPressed: onAssignTap,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}