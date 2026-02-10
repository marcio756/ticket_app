import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/ticket_list_controller.dart';
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

    final success = await ref.read(ticketListControllerProvider.notifier).createTicket(
      _titleController.text.trim(),
      _descriptionController.text.trim(),
      _selectedPriority,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      context.pop(); // Volta para a lista
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ticket criado com sucesso!')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao criar ticket. Tente novamente.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Ticket')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                hint: 'Detalhe o seu problema...',
                controller: _descriptionController,
                keyboardType: TextInputType.multiline,
                // hack simples para área de texto maior
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