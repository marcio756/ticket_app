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
    // Helper para criar utilizador desconhecido caso venha null da API
    UserModel safeUser() {
      if (json['user'] != null) {
        return UserModel.fromJson(json['user']);
      }
      return UserModel(
        id: 0, 
        name: 'Utilizador Desconhecido', 
        email: '', 
        role: 'customer'
      );
    }

    return TicketMessageModel(
      id: json['id'] is int ? json['id'] : 0,
      message: json['message']?.toString() ?? '',
      // Tenta ler 'attachment_url' (Resource) ou 'attachment_path' (Raw Model)
      attachmentUrl: json['attachment_url']?.toString() ?? json['attachment_path']?.toString(),
      user: safeUser(),
      // Tenta fazer parse da data, se falhar usa data atual
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      createdAtHuman: json['created_at_human']?.toString() ?? '',
    );
  }

  bool isMe(int myUserId) => user.id == myUserId;

  String get timeFormatted => DateFormat('HH:mm').format(createdAt);
}