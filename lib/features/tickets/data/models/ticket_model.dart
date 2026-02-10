import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'ticket_message_model.dart'; // Importa o modelo de mensagens

class TicketModel {
  final int id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final DateTime createdAt;
  final List<TicketMessageModel> messages; // <--- NOVO CAMPO

  TicketModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.messages,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    // Processar a lista de mensagens se ela vier no JSON
    var messagesList = <TicketMessageModel>[];
    if (json['messages'] != null) {
      messagesList = (json['messages'] as List)
          .map((m) => TicketMessageModel.fromJson(m))
          .toList();
    }

    return TicketModel(
      id: json['id'],
      title: json['title'] ?? 'Sem Título',
      description: json['description'] ?? '',
      status: json['status'] ?? 'open',
      priority: json['priority'] ?? 'low',
      createdAt: DateTime.parse(json['created_at']),
      messages: messagesList, // <--- Atribui a lista
    );
  }

  // --- Helpers UI (Mantêm-se iguais) ---
  String get formattedDate => DateFormat('d MMM yyyy').format(createdAt);

  Color get statusColor {
    switch (status) {
      case 'open': return Colors.blue;
      case 'in_progress': return Colors.orange;
      case 'resolved': return Colors.green;
      case 'closed': return Colors.grey;
      default: return Colors.black;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'open': return 'Aberto';
      case 'in_progress': return 'Em Progresso';
      case 'resolved': return 'Resolvido';
      case 'closed': return 'Fechado';
      default: return status;
    }
  }

  Color get priorityColor {
    switch (priority) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange.shade800;
      case 'low': return Colors.green.shade700;
      default: return Colors.grey;
    }
  }
}