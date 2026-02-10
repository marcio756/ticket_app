import 'package:flutter/material.dart';
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
      id: json['id'] is int ? json['id'] : 0,
      title: json['title']?.toString() ?? 'Sem Título',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'open',
      priority: json['priority']?.toString() ?? 'medium',
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      assignedTo: json['assigned_to'] != null ? UserModel.fromJson(json['assigned_to']) : null,
      messages: (json['messages'] as List?)
              ?.map((e) => TicketMessageModel.fromJson(e))
              .toList() ??
          [],
      // Proteção contra data nula
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  /// Método copyWith para permitir atualizações de estado imutáveis
  TicketModel copyWith({
    int? id,
    String? title,
    String? description,
    String? status,
    String? priority,
    UserModel? user,
    UserModel? assignedTo,
    List<TicketMessageModel>? messages,
    DateTime? createdAt,
  }) {
    return TicketModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      user: user ?? this.user,
      assignedTo: assignedTo ?? this.assignedTo,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // --- GETTERS AUXILIARES ---

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
    return "${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}";
  }
}