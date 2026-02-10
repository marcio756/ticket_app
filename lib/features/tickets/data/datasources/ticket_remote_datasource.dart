import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/ticket_model.dart';
import '../models/ticket_message_model.dart';

class TicketRemoteDatasource {
  final ApiClient _client;

  TicketRemoteDatasource(this._client);

  /// Obtém a lista de tickets (com suporte a filtros)
  Future<List<TicketModel>> getTickets({Map<String, dynamic>? queryParameters}) async {
    final response = await _client.get('/tickets', queryParameters: queryParameters);
    
    // A paginação do Laravel devolve sempre dentro de 'data'
    final listData = response.data['data'] as List;
    
    return listData.map((e) => TicketModel.fromJson(e)).toList();
  }

  /// Obtém um ticket específico pelo ID
  Future<TicketModel> getTicket(int id) async {
    final response = await _client.get('/tickets/$id');
    
    // CORREÇÃO CRÍTICA:
    // O endpoint 'show' do Laravel (TicketApiController) devolve o objeto direto.
    // O endpoint 'index' devolve paginado dentro de 'data'.
    // Esta linha verifica ambos os casos para evitar erros de Null.
    final data = response.data['data'] ?? response.data;

    return TicketModel.fromJson(data);
  }

  Future<TicketModel> createTicket(Map<String, dynamic> data) async {
    final response = await _client.post('/tickets', data: data);
    // Create costuma retornar o objeto criado, verificamos se vem em 'data' ou direto
    final responseData = response.data['data'] ?? response.data;
    return TicketModel.fromJson(responseData);
  }

  /// Envia mensagem com anexo opcional
  Future<TicketMessageModel> addMessage(int ticketId, String message, {File? attachment}) async {
    final formData = FormData.fromMap({
      'message': message,
    });

    if (attachment != null) {
      String fileName = attachment.path.split('/').last;
      
      formData.files.add(MapEntry(
        'attachment',
        await MultipartFile.fromFile(
          attachment.path,
          filename: fileName,
        ),
      ));
    }

    final response = await _client.post(
      '/tickets/$ticketId/messages',
      data: formData,
    );

    // O TicketMessageResource do Laravel geralmente envolve em 'data'
    final responseData = response.data['data'] ?? response.data;
    return TicketMessageModel.fromJson(responseData);
  }

  Future<bool> assignTicketToMe(int ticketId) async {
    try {
      await _client.post('/tickets/$ticketId/assign');
      return true;
    } catch (e) {
      return false;
    }
  }
}