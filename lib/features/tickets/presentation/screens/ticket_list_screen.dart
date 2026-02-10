import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // Import necessário para context.push
import '../controllers/ticket_list_controller.dart';
import '../widgets/ticket_card.dart';

class TicketListScreen extends ConsumerWidget {
  const TicketListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsState = ref.watch(ticketListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Tickets'),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Criar Ticket em breve...')),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: ticketsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erro: ${error.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(ticketListProvider),
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
        data: (tickets) {
          if (tickets.isEmpty) {
            return const Center(
              child: Text('Não existem tickets.'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(ticketListProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tickets.length,
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                return TicketCard(
                  ticket: ticket,
                  onTap: () {
                    context.push('/tickets/${ticket.id}');
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}