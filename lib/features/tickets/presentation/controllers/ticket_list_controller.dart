import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart'; // Import do Provider
import '../../data/datasources/ticket_remote_datasource.dart';
import '../../data/models/ticket_model.dart';

final ticketListControllerProvider =
    StateNotifierProvider.autoDispose<TicketListController, AsyncValue<List<TicketModel>>>((ref) {
  // AQUI: Lemos o apiClientProvider e passamos para o Datasource
  final client = ref.watch(apiClientProvider);
  return TicketListController(TicketRemoteDatasource(client));
});

class TicketListController extends StateNotifier<AsyncValue<List<TicketModel>>> {
  final TicketRemoteDatasource _dataSource;

  TicketListController(this._dataSource) : super(const AsyncValue.loading()) {
    loadTickets();
  }

  Future<void> loadTickets({String? search, String? status, String? priority}) async {
    try {
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

      final tickets = await _dataSource.getTickets(); // Nota: O método getTickets no datasource que partilhaste não aceita params, vê nota abaixo*

      state = AsyncValue.data(tickets);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> createTicket(String title, String description, String priority) async {
    try {
      await _dataSource.createTicket({
        'title': title,
        'description': description,
        'priority': priority,
      });
      
      await loadTickets(); 
      return true;
    } catch (e) {
      return false;
    }
  }
}