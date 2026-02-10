import 'package:flutter/material.dart';
import '../../data/models/ticket_model.dart';

/// Displays the static details of a ticket (Header, Status, Description, User Info).
class TicketDetailHeader extends StatelessWidget {
  final TicketModel ticket;

  const TicketDetailHeader({
    super.key,
    required this.ticket,
  });

  @override
  Widget build(BuildContext context) {
    // Logic to determine if the user has support time remaining
    final ticketOwner = ticket.user;
    final ownerHasTime = (ticketOwner?.dailySupportSeconds ?? 0) > 0;

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
            // Visual badge for Remaining Time
            if (ticket.user != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      ownerHasTime ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: ownerHasTime
                          ? Colors.green.shade200
                          : Colors.red.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer,
                        size: 12,
                        color: ownerHasTime
                            ? Colors.green.shade700
                            : Colors.red.shade700),
                    const SizedBox(width: 4),
                    Text(
                      ticket.user!.formattedSupportTime,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: ownerHasTime
                              ? Colors.green.shade800
                              : Colors.red.shade800),
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
                // [CORREÇÃO] Substituído withOpacity por withValues
                backgroundColor: ticket.statusColor.withValues(alpha: 0.1),
                labelStyle: TextStyle(
                    color: ticket.statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text('Prioridade ${ticket.priority.toUpperCase()}'),
                // [CORREÇÃO] Substituído withOpacity por withValues
                backgroundColor: ticket.priorityColor.withValues(alpha: 0.1),
                labelStyle: TextStyle(
                    color: ticket.priorityColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
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
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey),
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
          _buildUserInfos(),
        ],
      ),
    );
  }

  Widget _buildUserInfos() {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          leading: const Icon(Icons.person_outline, size: 20),
          title: Text(ticket.user?.name ?? "Desconhecido",
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          subtitle: Text(ticket.user?.email ?? "",
              style: const TextStyle(fontSize: 12)),
        ),
        if (ticket.assignedTo != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading:
                const Icon(Icons.support_agent, size: 20, color: Colors.blue),
            title: Text(ticket.assignedTo!.name,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: Text('Técnico Responsável',
                style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
          ),
      ],
    );
  }
}