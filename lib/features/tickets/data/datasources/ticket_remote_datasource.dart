import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/ticket_model.dart';
import '../models/ticket_message_model.dart';

class TicketRemoteDataSource {
  final ApiClient _apiClient;

  TicketRemoteDataSource({ApiClient? apiClient}) 
      : _apiClient = apiClient ?? ApiClient();

  /// Fetches the list of tickets with optional filters.
  Future<List<TicketModel>> getTickets({Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _apiClient.client.get(
        '/tickets',
        queryParameters: queryParameters,
      );
      final List<dynamic> data = response.data['data'] ?? response.data;
      return data.map((json) => TicketModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Fetches details for a specific ticket.
  Future<TicketModel> getTicketDetails(int ticketId) async {
    try {
      final response = await _apiClient.client.get('/tickets/$ticketId');
      final data = response.data['data'] ?? response.data;
      return TicketModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Creates a new ticket.
  Future<TicketModel> createTicket(Map<String, dynamic> ticketData) async {
    try {
      final response = await _apiClient.client.post('/tickets', data: ticketData);
      final data = response.data['data'] ?? response.data;
      return TicketModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Sends a new message to a ticket (with optional attachment).
  Future<TicketMessageModel> sendMessage(int ticketId, String message, {File? attachment}) async {
    try {
      if (attachment != null) {
        final formData = FormData.fromMap({
          'message': message,
          'attachment': await MultipartFile.fromFile(attachment.path),
        });

        final response = await _apiClient.client.post(
          '/tickets/$ticketId/messages',
          data: formData,
        );
        final data = response.data['data'] ?? response.data;
        return TicketMessageModel.fromJson(data);
      } else {
        final response = await _apiClient.client.post(
          '/tickets/$ticketId/messages',
          data: {'message': message},
        );
        final data = response.data['data'] ?? response.data;
        return TicketMessageModel.fromJson(data);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Atribui o ticket ao utilizador autenticado.
  Future<void> assignTicketToMe(int ticketId) async {
    try {
      await _apiClient.client.post('/tickets/$ticketId/assign');
    } catch (e) {
      rethrow;
    }
  }
}