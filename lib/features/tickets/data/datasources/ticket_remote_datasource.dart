import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/ticket_model.dart';
import '../models/ticket_message_model.dart';

class TicketRemoteDatasource {
  final ApiClient _client;

  TicketRemoteDatasource(this._client);

  Future<List<TicketModel>> getTickets({
    String? status,
    String? priority,
    String? search,
  }) async {
    final Map<String, dynamic> query = {};
    if (status != null && status != 'all') query['status'] = status;
    if (priority != null && priority != 'all') query['priority'] = priority;
    if (search != null && search.isNotEmpty) query['search'] = search;

    final response = await _client.get('/tickets', queryParameters: query);
    
    return (response.data['data'] as List)
        .map((e) => TicketModel.fromJson(e))
        .toList();
  }

  Future<TicketModel> getTicket(int id) async {
    final response = await _client.get('/tickets/$id');
    // A API retorna o objeto TicketResource diretamente ou dentro de 'data' dependendo da implementação.
    // O TicketResource padrão do Laravel envolve em 'data'.
    final data = response.data['data'] ?? response.data;
    return TicketModel.fromJson(data);
  }

  Future<TicketModel> createTicket(String title, String description, String priority) async {
    final response = await _client.post('/tickets', data: {
      'title': title,
      'description': description,
      'priority': priority,
    });
    return TicketModel.fromJson(response.data);
  }

  Future<TicketMessageModel> addMessage(int ticketId, String? message, {File? attachment}) async {
    final formData = FormData.fromMap({
      if (message != null && message.isNotEmpty) 'message': message,
      if (attachment != null)
        'attachment': await MultipartFile.fromFile(attachment.path),
    });

    final response = await _client.post('/tickets/$ticketId/messages', data: formData);
    // Assumindo que o TicketMessageResource também pode vir envolvido em 'data'
    final data = response.data['data'] ?? response.data;
    return TicketMessageModel.fromJson(data);
  }

  Future<bool> assignTicketToMe(int ticketId) async {
    try {
      await _client.post('/tickets/$ticketId/assign');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<int?> trackSupportTime(int ticketId, int seconds) async {
    try {
      final response = await _client.post(
        '/tickets/$ticketId/track-time',
        data: {'seconds': seconds},
      );
      // A API retorna { 'message': '...', 'remaining_seconds': 1230 }
      return response.data['remaining_seconds'] as int?;
    } catch (e) {
      // Se falhar, retornamos null para não atualizar a UI incorretamente
      return null;
    }
  }
}