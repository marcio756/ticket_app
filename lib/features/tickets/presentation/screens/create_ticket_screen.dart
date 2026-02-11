import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/ticket_list_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../users/presentation/controllers/user_list_controller.dart';
import '../../../../shared/components/inputs/app_text_field.dart';
import '../../../../shared/components/buttons/app_primary_button.dart';

class CreateTicketScreen extends ConsumerStatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  ConsumerState<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends ConsumerState<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedPriority = 'low';
  int? _selectedUserId; 
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Early binding of UI controllers to avoid use_build_context_synchronously warning
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    final success = await ref.read(ticketListControllerProvider.notifier).createTicket(
      _titleController.text.trim(),
      _descriptionController.text.trim(),
      _selectedPriority,
      userId: _selectedUserId,
    );

    if (!mounted) return; // Strict reliance on State.mounted

    setState(() => _isLoading = false);

    if (success) {
      router.pop(); // Replaced context.pop() with the early-binded router
      messenger.showSnackBar(
        const SnackBar(content: Text('Ticket criado com sucesso!')),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Erro ao criar ticket. Verifique os dados e tente novamente.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final currentUser = authState.user;
    final isStaff = currentUser != null && currentUser.isSupporter;

    final usersState = isStaff ? ref.watch(userListControllerProvider) : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Novo Ticket')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              
              if (isStaff && usersState != null) ...[
                const Text('Atribuir ao Cliente', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                usersState.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => const Text('Erro a carregar clientes', style: TextStyle(color: Colors.red)),
                  data: (users) {
                    final customers = users.where((u) => u.role == 'customer').toList();
                    
                    return DropdownButtonFormField<int>(
                      initialValue: _selectedUserId, // Fix for deprecated 'value' field
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      hint: const Text('Selecione um cliente'),
                      items: customers.map((u) => DropdownMenuItem(
                        value: u.id, 
                        child: Text(u.name)
                      )).toList(),
                      onChanged: (val) => setState(() => _selectedUserId = val),
                      validator: (v) => v == null ? 'Seleção de cliente obrigatória' : null,
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],

              AppTextField(
                label: 'Título',
                hint: 'Resumo do problema',
                controller: _titleController,
                validator: (v) => v == null || v.isEmpty ? 'Título obrigatório' : null,
              ),
              const SizedBox(height: 16),
              
              const Text('Prioridade', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedPriority,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Baixa')),
                  DropdownMenuItem(value: 'medium', child: Text('Média')),
                  DropdownMenuItem(value: 'high', child: Text('Alta')),
                ],
                onChanged: (val) => setState(() => _selectedPriority = val!),
              ),
              const SizedBox(height: 16),

              AppTextField(
                label: 'Descrição',
                hint: 'Detalhe o problema...',
                controller: _descriptionController,
                keyboardType: TextInputType.multiline,
                suffixIcon: const SizedBox(height: 100, width: 0), 
                validator: (v) => v == null || v.isEmpty ? 'Descrição obrigatória' : null,
              ),
              
              const SizedBox(height: 32),
              
              AppPrimaryButton(
                text: 'Criar Ticket',
                isLoading: _isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}