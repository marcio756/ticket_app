import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/ticket_remote_datasource.dart';
import '../../data/models/ticket_model.dart';

/// Provider for managing the details of a specific ticket.
/// The family modifier allows passing the ticketId, and we inject the DataSource.
final ticketDetailControllerProvider = StateNotifierProvider.autoDispose
    .family<TicketDetailController, AsyncValue<TicketModel?>, int>((ref, ticketId) {
  // CORREÇÃO: Passar explicitamente o ID e o DataSource para o construtor
  return TicketDetailController(
    ticketId: ticketId,
    dataSource: TicketRemoteDataSource(),
  );
});

class TicketDetailController extends StateNotifier<AsyncValue<TicketModel?>> {
  final int ticketId;
  final TicketRemoteDataSource _dataSource;

  // Constructor with named parameters for better clarity
  TicketDetailController({
    required this.ticketId,
    required TicketRemoteDataSource dataSource,
  })  : _dataSource = dataSource,
        super(const AsyncValue.loading()) {
    loadTicket();
  }

  /// Fetches ticket details from the remote source.
  Future<void> loadTicket() async {
    try {
      final ticket = await _dataSource.getTicketDetails(ticketId);
      state = AsyncValue.data(ticket);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Sends a new message and refreshes the ticket data.
  /// Returns true if successful, false otherwise.
  Future<bool> addMessage(String message) async {
    try {
      await _dataSource.sendMessage(ticketId, message);
      await loadTicket();
      return true;
    } catch (e) {
      debugPrint('Error sending message: $e');
      return false;
    }
  }
}