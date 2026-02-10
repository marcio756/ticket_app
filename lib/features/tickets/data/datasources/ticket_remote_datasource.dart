import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/ticket_model.dart';
import '../models/ticket_message_model.dart';

class TicketRemoteDataSource {
  final ApiClient _apiClient;

  TicketRemoteDataSource({ApiClient? apiClient}) 
      : _apiClient = apiClient ?? ApiClient();

  Future<List<TicketModel>> getTickets() async {
    try {
      final response = await _apiClient.client.get('/tickets');
      final List<dynamic> data = response.data['data'];
      return data.map((json) => TicketModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Obtém os detalhes de um ticket (incluindo mensagens, se o backend enviar)
  /// Nota: Se o teu backend não enviar mensagens no 'show', teremos de criar um método 'getMessages' separado.
  Future<TicketModel> getTicketDetails(int ticketId) async {
    try {
      final response = await _apiClient.client.get('/tickets/$ticketId');
      return TicketModel.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  /// Envia uma nova mensagem com anexo opcional
  Future<TicketMessageModel> sendMessage(int ticketId, String message, File? attachment) async {
    try {
      // Prepara o FormData para envio de ficheiro
      final formData = FormData.fromMap({
        'message': message,
      });

      if (attachment != null) {
        formData.files.add(MapEntry(
          'attachment',
          await MultipartFile.fromFile(attachment.path),
        ));
      }

      final response = await _apiClient.client.post(
        '/tickets/$ticketId/messages',
        data: formData,
      );

      // O backend retorna a mensagem criada (TicketMessageResource)
      return TicketMessageModel.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }
}