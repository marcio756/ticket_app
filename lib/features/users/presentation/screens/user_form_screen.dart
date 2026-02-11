import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/models/user_model.dart';
import '../controllers/user_list_controller.dart';
import '../../../../shared/components/inputs/app_text_field.dart';
import '../../../../shared/components/buttons/app_primary_button.dart';

class UserFormScreen extends ConsumerStatefulWidget {
  final UserModel? user; 

  const UserFormScreen({super.key, this.user});

  @override
  ConsumerState<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends ConsumerState<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  late TextEditingController _adminPasswordController; // NOVO: Para validação
  
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
    _adminPasswordController = TextEditingController();
    
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
    _adminPasswordController.dispose();
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

    if (!_isEditing || _passwordController.text.isNotEmpty) {
      data['password'] = _passwordController.text;
      data['password_confirmation'] = _confirmPasswordController.text;
    }

    if (_isEditing) {
      data['admin_password'] = _adminPasswordController.text; // Passa a password de segurança
    }

    final controller = ref.read(userListControllerProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    bool success;
    if (_isEditing) {
      success = await controller.updateUser(widget.user!.id, data);
    } else {
      success = await controller.createUser(data);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      navigator.pop(); 
      messenger.showSnackBar(
        SnackBar(content: Text(_isEditing ? 'Utilizador atualizado!' : 'Utilizador criado!')),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Erro ao salvar. Password incorreta ou e-mail duplicado.'), backgroundColor: Colors.red),
      );
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
              
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Função / Cargo',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'customer', child: Text('Cliente')),
                  DropdownMenuItem(value: 'supporter', child: Text('Suporte')),
                  DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                ],
                onChanged: (val) => setState(() => _selectedRole = val!),
              ),
              const SizedBox(height: 24),
              
              Text(
                _isEditing ? 'Alterar Password do Utilizador (Opcional)' : 'Definir Password',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              
              AppTextField(
                controller: _passwordController,
                label: 'Password',
                obscureText: true,
                validator: (v) {
                  if (!_isEditing && (v == null || v.length < 8)) return 'Mínimo 8 caracteres';
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
              
              // SEÇÃO DE SEGURANÇA (Aparece apenas na edição)
              if (_isEditing) ...[
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Segurança Obrigatória',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.red),
                ),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _adminPasswordController,
                  label: 'A sua Password (Admin/Suporte)',
                  hint: 'Insira a sua password para autorizar a edição',
                  obscureText: true,
                  validator: (v) => v == null || v.isEmpty ? 'Confirmação obrigatória' : null,
                ),
              ],
              
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