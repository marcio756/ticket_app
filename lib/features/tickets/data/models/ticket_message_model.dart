import '../../../../features/auth/data/models/user_model.dart';
import 'package:intl/intl.dart';

class TicketMessageModel {
  final int id;
  final String message;
  final String? attachmentUrl;
  final UserModel user;
  final DateTime createdAt;
  final String createdAtHuman;

  TicketMessageModel({
    required this.id,
    required this.message,
    this.attachmentUrl,
    required this.user,
    required this.createdAt,
    required this.createdAtHuman,
  });

  factory TicketMessageModel.fromJson(Map<String, dynamic> json) {
    return TicketMessageModel(
      id: json['id'],
      message: json['message'] ?? '',
      attachmentUrl: json['attachment_url'],
      user: UserModel.fromJson(json['user']),
      createdAt: DateTime.parse(json['created_at']),
      createdAtHuman: json['created_at_human'] ?? '',
    );
  }

  // Helper para verificar se a mensagem é minha (do utilizador logado)
  bool isMe(int myUserId) => user.id == myUserId;

  // Formatação de hora para o chat (Ex: 14:30)
  String get timeFormatted => DateFormat('HH:mm').format(createdAt);
}