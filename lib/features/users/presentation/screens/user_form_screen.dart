import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/models/user_model.dart';
import '../controllers/user_list_controller.dart';
// Importa os teus componentes partilhados
import '../../../../shared/components/inputs/app_text_field.dart';
import '../../../../shared/components/buttons/app_primary_button.dart';

class UserFormScreen extends ConsumerStatefulWidget {
  final UserModel? user; // Se null = Criar, Se preenchido = Editar

  const UserFormScreen({super.key, this.user});

  @override
  ConsumerState<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends ConsumerState<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  
  String _selectedRole = 'customer';
  bool _isLoading = false;

  bool get _isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    
    if (_isEditing) {
      _selectedRole = widget.user!.role;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final data = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'role': _selectedRole,
    };

    // Só envia password se for criação OU se o campo foi preenchido na edição
    if (!_isEditing || _passwordController.text.isNotEmpty) {
      data['password'] = _passwordController.text;
      data['password_confirmation'] = _confirmPasswordController.text;
    }

    final controller = ref.read(userListControllerProvider.notifier);
    bool success;

    if (_isEditing) {
      success = await controller.updateUser(widget.user!.id, data);
    } else {
      success = await controller.createUser(data);
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context); // Volta para a lista
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'Utilizador atualizado!' : 'Utilizador criado!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao salvar. Verifique os dados.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Utilizador' : 'Novo Utilizador'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _nameController,
                label: 'Nome',
                hint: 'Nome completo',
                validator: (v) => v == null || v.isEmpty ? 'Nome obrigatório' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'exemplo@email.com',
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v == null || !v.contains('@') ? 'Email inválido' : null,
              ),
              const SizedBox(height: 16),
              
              // Dropdown de Role (Nativo por enquanto, para simplificar)
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Função / Cargo',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'customer', child: Text('Cliente')),
                  DropdownMenuItem(value: 'support', child: Text('Suporte')),
                  DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                ],
                onChanged: (val) => setState(() => _selectedRole = val!),
              ),
              const SizedBox(height: 24),
              
              Text(
                _isEditing ? 'Alterar Password (Opcional)' : 'Definir Password',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              
              AppTextField(
                controller: _passwordController,
                label: 'Password',
                obscureText: true,
                validator: (v) {
                  if (!_isEditing && (v == null || v.length < 8)) {
                    return 'Mínimo 8 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _confirmPasswordController,
                label: 'Confirmar Password',
                obscureText: true,
                validator: (v) {
                  if (_passwordController.text.isNotEmpty && v != _passwordController.text) {
                    return 'As passwords não coincidem';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 32),
              
              AppPrimaryButton(
                text: _isEditing ? 'Guardar Alterações' : 'Criar Utilizador',
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