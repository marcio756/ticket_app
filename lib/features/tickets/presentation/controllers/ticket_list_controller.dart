import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/ticket_remote_datasource.dart';
import '../../data/models/ticket_model.dart';
import '../../../auth/data/models/user_model.dart';

final ticketListControllerProvider =
    StateNotifierProvider.autoDispose<TicketListController, AsyncValue<List<TicketModel>>>((ref) {
  final client = ref.watch(apiClientProvider);
  return TicketListController(TicketRemoteDatasource(client));
});

/// Manages the state for the list of tickets.
class TicketListController extends StateNotifier<AsyncValue<List<TicketModel>>> {
  final TicketRemoteDatasource _dataSource;

  TicketListController(this._dataSource) : super(const AsyncValue.loading()) {
    loadTickets();
  }

  /// Fetches the tickets from the remote data source applying the given filters.
  /// 
  /// @param search Optional search query.
  /// @param status Optional ticket status filter.
  /// @param priority Optional ticket priority filter.
  /// @param unassigned Optional flag to filter only tickets with no assigned support.
  /// @param customerIds Optional list of customer IDs to filter by.
  Future<void> loadTickets({
    String? search, 
    String? status, 
    String? priority, 
    bool? unassigned,
    List<int>? customerIds,
  }) async {
    try {
      final tickets = await _dataSource.getTickets(
        search: search,
        status: status,
        priority: priority,
        unassigned: unassigned,
        customerIds: customerIds,
      );

      state = AsyncValue.data(tickets);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Helper method to fetch available customers for the filter dialog.
  Future<List<UserModel>> getAvailableCustomers() async {
    return await _dataSource.getAvailableCustomers();
  }

  /// Creates a new ticket and updates the current state list if successful.
  /// 
  /// @param title Ticket title.
  /// @param description Ticket description.
  /// @param priority Ticket priority.
  /// @param userId Optional user ID if staff is creating the ticket on behalf of a customer.
  /// @return Future<bool> indicating success or failure.
  Future<bool> createTicket(String title, String description, String priority, {int? userId}) async {
    try {
      final newTicket = await _dataSource.createTicket(title, description, priority, userId: userId);

      state.whenData((tickets) {
        state = AsyncValue.data([newTicket, ...tickets]);
      });
      
      return true;
    } catch (e) {
      return false;
    }
  }
}