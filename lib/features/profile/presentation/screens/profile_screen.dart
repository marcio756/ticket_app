import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../../../shared/components/inputs/app_text_field.dart';
import '../../../../shared/components/buttons/app_primary_button.dart';

/// Screen responsible for displaying and editing the logged-in user's profile.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _newPasswordConfirmController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _newPasswordConfirmController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _newPasswordConfirmController.dispose();
    super.dispose();
  }

  /// Handles the submission of the updated profile data.
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final messenger = ScaffoldMessenger.of(context);
    
    final success = await ref.read(authControllerProvider.notifier).updateProfile(
      _nameController.text.trim(),
      _emailController.text.trim(),
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
      newPasswordConfirmation: _newPasswordConfirmController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _newPasswordConfirmController.clear();
      
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Perfil atualizado com sucesso!'), 
          backgroundColor: Colors.green
        ),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Erro ao atualizar. Verifique a sua password atual ou e-mail.'), 
          backgroundColor: Colors.red
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('A carregar perfil...')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Icon(Icons.person, size: 50, color: Theme.of(context).primaryColor),
                ),
              ),
              const SizedBox(height: 32),
              
              AppTextField(
                label: 'Nome Completo',
                controller: _nameController,
                validator: (v) => v == null || v.isEmpty ? 'O nome é obrigatório' : null,
              ),
              const SizedBox(height: 16),
              
              AppTextField(
                label: 'Endereço de E-mail',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'O e-mail é obrigatório';
                  if (!v.contains('@')) return 'E-mail inválido';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              const Text('Alterar Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              const SizedBox(height: 16),

              AppTextField(
                label: 'Password Atual',
                hint: 'Necessária se quiser alterar a password',
                controller: _currentPasswordController,
                obscureText: true,
                validator: (v) {
                  if (_newPasswordController.text.isNotEmpty && (v == null || v.isEmpty)) {
                    return 'Insira a password atual para continuar';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              AppTextField(
                label: 'Nova Password',
                controller: _newPasswordController,
                obscureText: true,
                validator: (v) {
                  if (v != null && v.isNotEmpty && v.length < 8) return 'Mínimo de 8 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              AppTextField(
                label: 'Confirmar Nova Password',
                controller: _newPasswordConfirmController,
                obscureText: true,
                validator: (v) {
                  if (_newPasswordController.text.isNotEmpty && v != _newPasswordController.text) {
                    return 'As passwords não coincidem';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              
              AppPrimaryButton(
                text: 'Guardar Alterações',
                isLoading: _isLoading,
                onPressed: _updateProfile,
              ),
              
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  ref.read(authControllerProvider.notifier).logout();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sair da Conta (Logout)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}