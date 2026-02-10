import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/ticket_list_controller.dart';
import '../widgets/ticket_card.dart';

class TicketListScreen extends ConsumerStatefulWidget {
  const TicketListScreen({super.key});

  @override
  ConsumerState<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends ConsumerState<TicketListScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _selectedStatus = 'all';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _refreshList() {
    ref.read(ticketListControllerProvider.notifier).loadTickets(
      search: _searchController.text,
      status: _selectedStatus,
    );
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _refreshList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ticketState = ref.watch(ticketListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tickets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/tickets/create'), // Se tiveres rota de criar
          ),
        ],
      ),
      body: Column(
        children: [
          // --- BARRA DE PESQUISA E FILTROS ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Pesquisar ticket...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  ),
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip('Todos', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Abertos', 'open'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Resolvidos', 'resolved'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Fechados', 'closed'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // --- LISTA DE RESULTADOS ---
          Expanded(
            child: ticketState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Erro: $err')),
              data: (tickets) {
                if (tickets.isEmpty) {
                  return const Center(child: Text('Nenhum ticket encontrado.'));
                }
                return RefreshIndicator(
                  onRefresh: () async => _refreshList(),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: tickets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final ticket = tickets[index];
                      return TicketCard(
                        ticket: ticket,
                        onTap: () => context.push('/tickets/${ticket.id}'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedStatus == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          setState(() => _selectedStatus = value);
          _refreshList();
        }
      },
    );
  }
}