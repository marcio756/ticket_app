import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/ticket_remote_datasource.dart';
import '../../data/models/ticket_model.dart';

final ticketListControllerProvider =
    StateNotifierProvider.autoDispose<TicketListController, AsyncValue<List<TicketModel>>>((ref) {
  final client = ref.watch(apiClientProvider);
  return TicketListController(TicketRemoteDatasource(client));
});

class TicketListController extends StateNotifier<AsyncValue<List<TicketModel>>> {
  // [CORREÇÃO 1] Nome consistente da variável (com 'S' maiúsculo)
  final TicketRemoteDatasource _dataSource;

  TicketListController(this._dataSource) : super(const AsyncValue.loading()) {
    loadTickets();
  }

  Future<void> loadTickets({String? search, String? status, String? priority}) async {
    try {
      // O teu datasource getTickets aceita argumentos nomeados opcionais
      final tickets = await _dataSource.getTickets(
        search: search,
        status: status,
        priority: priority
      );

      state = AsyncValue.data(tickets);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // [CORREÇÃO 2] Alterado para receber 3 Strings em vez de um Map.
  // Isto resolve os erros no ecrã de criação.
  Future<bool> createTicket(String title, String description, String priority) async {
    try {
      // Guarda o estado atual para não perder a lista se falhar (opcional)
      // ou coloca em loading se preferires bloquear a UI
      // state = const AsyncValue.loading(); 
      
      // Usa a variável correta _dataSource
      final newTicket = await _dataSource.createTicket(title, description, priority);

      // Atualiza a lista localmente adicionando o novo ticket no topo
      state.whenData((tickets) {
        state = AsyncValue.data([newTicket, ...tickets]);
      });
      
      return true;
    } catch (e) {
      // Se der erro, não limpamos a lista, apenas mostramos o erro (ou tratamos na UI)
      // state = AsyncValue.error(e, st); 
      return false;
    }
  }
}