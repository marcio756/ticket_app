import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/ticket_model.dart';
import '../models/ticket_message_model.dart';
import '../../../auth/data/models/user_model.dart';

/// Handles all remote API calls related to Tickets.
class TicketRemoteDatasource {
  final ApiClient _client;

  TicketRemoteDatasource(this._client);

  /// Retrieves a list of tickets based on provided filters.
  Future<List<TicketModel>> getTickets({
    String? status,
    String? priority,
    String? search,
    bool? unassigned,
    List<int>? customerIds,
  }) async {
    final Map<String, dynamic> query = {};
    if (status != null && status != 'all') query['status'] = status;
    if (priority != null && priority != 'all') query['priority'] = priority;
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (unassigned != null && unassigned) query['unassigned'] = 'true';
    if (customerIds != null && customerIds.isNotEmpty) query['customer_ids'] = customerIds.join(',');

    final response = await _client.get('/tickets', queryParameters: query);
    
    return (response.data['data'] as List)
        .map((e) => TicketModel.fromJson(e))
        .toList();
  }

  /// Retrieves the list of available customers for the filter dropdown.
  Future<List<UserModel>> getAvailableCustomers() async {
    final response = await _client.get('/tickets/customers');
    return (response.data['data'] as List)
        .map((e) => UserModel.fromJson(e))
        .toList();
  }

  /// Retrieves a single ticket by its ID.
  Future<TicketModel> getTicket(int id) async {
    final response = await _client.get('/tickets/$id');
    final data = response.data['data'] ?? response.data;
    return TicketModel.fromJson(data);
  }

  /// Creates a new ticket in the backend.
  Future<TicketModel> createTicket(String title, String description, String priority, {int? userId}) async {
    final response = await _client.post('/tickets', data: {
      'title': title,
      'description': description,
      'priority': priority,
      if (userId != null) 'user_id': userId,
    });
    return TicketModel.fromJson(response.data);
  }

  /// Adds a new message (and optional attachment) to an existing ticket.
  Future<TicketMessageModel> addMessage(int ticketId, String? message, {File? attachment}) async {
    final formData = FormData.fromMap({
      if (message != null && message.isNotEmpty) 'message': message,
      if (attachment != null)
        'attachment': await MultipartFile.fromFile(attachment.path),
    });

    final response = await _client.post('/tickets/$ticketId/messages', data: formData);
    final data = response.data['data'] ?? response.data;
    return TicketMessageModel.fromJson(data);
  }

  /// Assigns a specific ticket to the currently logged in user.
  Future<bool> assignTicketToMe(int ticketId) async {
    try {
      await _client.post('/tickets/$ticketId/assign');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Deducts a specified amount of seconds from the ticket owner's support pool.
  Future<int?> trackSupportTime(int ticketId, int seconds) async {
    try {
      final response = await _client.post(
        '/tickets/$ticketId/track-time',
        data: {'seconds': seconds},
      );
      return response.data['remaining_seconds'] as int?;
    } catch (e) {
      return null;
    }
  }

  /// Partially updates a ticket's information (like its current status).
  Future<bool> updateStatus(int ticketId, String status) async {
    try {
      await _client.patch(
        '/tickets/$ticketId', 
        data: {'status': status},
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}