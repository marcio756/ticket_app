import 'package:flutter/material.dart'; // Importante para as Cores
import '../../../auth/data/models/user_model.dart';
import 'ticket_message_model.dart';

class TicketModel {
  final int id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final UserModel? user; 
  final UserModel? assignedTo;
  final List<TicketMessageModel> messages;
  final DateTime createdAt;

  TicketModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.user,
    this.assignedTo,
    this.messages = const [],
    required this.createdAt,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'],
      title: json['title'] ?? 'Sem Título',
      description: json['description'] ?? '',
      status: json['status'] ?? 'open',
      priority: json['priority'] ?? 'medium',
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      assignedTo: json['assigned_to'] != null ? UserModel.fromJson(json['assigned_to']) : null,
      messages: (json['messages'] as List?)
              ?.map((e) => TicketMessageModel.fromJson(e))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  // --- GETTERS AUXILIARES PARA UI (Resolve erros do TicketCard) ---

  String get statusLabel {
    switch (status) {
      case 'resolved': return 'Resolvido';
      case 'closed': return 'Fechado';
      default: return 'Aberto';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'resolved': return Colors.green;
      case 'closed': return Colors.grey;
      default: return Colors.blue;
    }
  }

  Color get priorityColor {
    switch (priority) {
      case 'high': return Colors.red;
      case 'low': return Colors.green;
      default: return Colors.orange;
    }
  }

  String get formattedDate {
    // Formatação simples YYYY-MM-DD
    return "${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}";
  }
}