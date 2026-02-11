import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/ticket_list_controller.dart';
import '../widgets/ticket_card.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/data/models/user_model.dart';

/// Screen responsible for displaying the list of tickets with search and filtering capabilities.
class TicketListScreen extends ConsumerStatefulWidget {
  const TicketListScreen({super.key});

  @override
  ConsumerState<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends ConsumerState<TicketListScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  
  String _selectedFilter = 'all';
  List<int> _selectedCustomerIds = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Refreshes the ticket list by applying the current search text and selected filter.
  void _refreshList() {
    String? status = _selectedFilter;
    bool? unassigned;

    if (_selectedFilter == 'unassigned') {
      status = 'all'; 
      unassigned = true;
    }

    ref.read(ticketListControllerProvider.notifier).loadTickets(
      search: _searchController.text,
      status: status,
      unassigned: unassigned,
      customerIds: _selectedCustomerIds,
    );
  }

  /// Debounces the search input to avoid spamming the API on every keystroke.
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _refreshList();
    });
  }

  /// Shows a custom dialog allowing the user to search and select multiple customers.
  Future<void> _showCustomerFilterDialog() async {
    final controller = ref.read(ticketListControllerProvider.notifier);
    
    showDialog(
      context: context,
      builder: (context) {
        return _CustomerMultiSelectDialog(
          initialSelectedIds: _selectedCustomerIds,
          fetchCustomers: controller.getAvailableCustomers,
          onApply: (selectedIds) {
            setState(() {
              _selectedCustomerIds = selectedIds;
            });
            _refreshList();
          },
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final ticketState = ref.watch(ticketListControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final currentUser = authState.user;
    final isStaff = currentUser != null && currentUser.isSupporter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tickets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/tickets/create'),
          ),
        ],
      ),
      body: Column(
        children: [
          // --- SEARCH AND FILTER SECTION ---
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
                
                Row(
                  children: [
                    Expanded(
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Filtrar por Status',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedFilter,
                            isExpanded: true,
                            isDense: true,
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('Todos')),
                              DropdownMenuItem(value: 'open', child: Text('Abertos')),
                              DropdownMenuItem(value: 'resolved', child: Text('Resolvidos')),
                              DropdownMenuItem(value: 'closed', child: Text('Fechados')),
                              DropdownMenuItem(value: 'unassigned', child: Text('Não Atribuídos')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedFilter = value);
                                _refreshList();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    if (isStaff) ...[
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        icon: const Icon(Icons.people),
                        label: Text(_selectedCustomerIds.isEmpty 
                            ? 'Clientes' 
                            : 'Clientes (${_selectedCustomerIds.length})'),
                        onPressed: _showCustomerFilterDialog,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // --- RESULTS LIST SECTION ---
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
}

/// Custom dialog to allow multi-selection of customers with a search bar.
class _CustomerMultiSelectDialog extends StatefulWidget {
  final List<int> initialSelectedIds;
  final Future<List<UserModel>> Function() fetchCustomers;
  final ValueChanged<List<int>> onApply;

  const _CustomerMultiSelectDialog({
    required this.initialSelectedIds,
    required this.fetchCustomers,
    required this.onApply,
  });

  @override
  State<_CustomerMultiSelectDialog> createState() => _CustomerMultiSelectDialogState();
}

class _CustomerMultiSelectDialogState extends State<_CustomerMultiSelectDialog> {
  late Future<List<UserModel>> _futureCustomers;
  List<int> _selectedIds = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.initialSelectedIds);
    _futureCustomers = widget.fetchCustomers();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filtrar por Clientes'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Pesquisar pelo nome...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<List<UserModel>>(
                future: _futureCustomers,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Erro ao carregar clientes.'));
                  }
                  
                  final allCustomers = snapshot.data ?? [];
                  final filteredCustomers = allCustomers.where((c) {
                    return c.name.toLowerCase().contains(_searchQuery);
                  }).toList();

                  if (filteredCustomers.isEmpty) {
                    return const Center(child: Text('Nenhum cliente disponível.'));
                  }

                  return ListView.builder(
                    itemCount: filteredCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = filteredCustomers[index];
                      final isSelected = _selectedIds.contains(customer.id);
                      return CheckboxListTile(
                        title: Text(customer.name),
                        value: isSelected,
                        onChanged: (bool? checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedIds.add(customer.id);
                            } else {
                              _selectedIds.remove(customer.id);
                            }
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => setState(() => _selectedIds.clear()),
          child: const Text('Limpar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onApply(_selectedIds);
            Navigator.pop(context);
          },
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
}