import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/ticket_remote_datasource.dart';
import '../../data/models/ticket_model.dart';

// O Provider principal:
// ticketListProvider devolve um AsyncValue<List<TicketModel>>
final ticketListProvider = FutureProvider.autoDispose<List<TicketModel>>((ref) async {
  // 1. Instancia o Datasource
  final dataSource = TicketRemoteDataSource();
  
  // 2. Pede os tickets (o Riverpod gere o loading/erro aqui)
  return await dataSource.getTickets();
});