import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/ticket_remote_datasource.dart';
import '../../data/models/ticket_model.dart';

// Provider for the ticket list state
final ticketListControllerProvider =
    StateNotifierProvider.autoDispose<TicketListController, AsyncValue<List<TicketModel>>>((ref) {
  return TicketListController(TicketRemoteDataSource());
});

class TicketListController extends StateNotifier<AsyncValue<List<TicketModel>>> {
  final TicketRemoteDataSource _dataSource;

  TicketListController(this._dataSource) : super(const AsyncValue.loading()) {
    // Load initial list
    loadTickets();
  }

  /// Loads tickets with optional filters (search, status, priority).
  Future<void> loadTickets({String? search, String? status, String? priority}) async {
    try {
      // Build query parameters
      final Map<String, dynamic> queryParams = {};
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (status != null && status != 'all') {
        queryParams['status'] = status;
      }
      if (priority != null && priority != 'all') {
        queryParams['priority'] = priority;
      }

      // Fetch from data source
      final tickets = await _dataSource.getTickets(queryParameters: queryParams);

      // Update state
      state = AsyncValue.data(tickets);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Creates a new ticket and refreshes the list upon success.
  /// Returns true if successful, false otherwise.
  Future<bool> createTicket(String title, String description, String priority) async {
    try {
      await _dataSource.createTicket({
        'title': title,
        'description': description,
        'priority': priority,
      });
      
      // Refresh the list to show the new ticket
      await loadTickets(); 
      return true;
    } catch (e) {
      // You might want to log the error here
      return false;
    }
  }
}