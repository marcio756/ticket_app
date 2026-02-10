import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/ticket_remote_datasource.dart';
import '../../data/models/ticket_model.dart';

final ticketDetailControllerProvider = StateNotifierProvider.autoDispose
    .family<TicketDetailController, AsyncValue<TicketModel?>, int>((ref, ticketId) {
  return TicketDetailController(
    ticketId: ticketId,
    dataSource: TicketRemoteDataSource(),
  );
});

class TicketDetailController extends StateNotifier<AsyncValue<TicketModel?>> {
  final int ticketId;
  final TicketRemoteDataSource _dataSource;

  TicketDetailController({
    required this.ticketId,
    required TicketRemoteDataSource dataSource,
  })  : _dataSource = dataSource,
        super(const AsyncValue.loading()) {
    loadTicket();
  }

  Future<void> loadTicket() async {
    try {
      final ticket = await _dataSource.getTicketDetails(ticketId);
      state = AsyncValue.data(ticket);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

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

  Future<bool> assignToMe() async {
    try {
      await _dataSource.assignTicketToMe(ticketId);
      await loadTicket();
      return true;
    } catch (e) {
      debugPrint('Error assigning ticket: $e');
      return false;
    }
  }
}