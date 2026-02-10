import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../shared/components/buttons/app_primary_button.dart';
import '../../../../shared/components/inputs/app_text_field.dart';
import '../controllers/auth_controller.dart';
import '../controllers/auth_state.dart';

/// The Login Screen responsible for user authentication.
class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Hooks for text controllers (automatically disposed)
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    
    // Hooks for form validation key
    final formKey = useMemoized(() => GlobalKey<FormState>());

    // Watch the auth state to show loading/error
    final authState = ref.watch(authControllerProvider);

    // Listen to state changes for error handling (SnackBar)
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.status == AuthStatus.failure && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo placeholder
                const Icon(
                  Icons.confirmation_number_outlined,
                  size: 64,
                  color: Colors.blue,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Bem-vindo de volta',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Insira as suas credenciais para aceder',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),

                // Email Input
                AppTextField(
                  label: 'Email',
                  hint: 'exemplo@email.com',
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor insira o email';
                    }
                    if (!value.contains('@')) {
                      return 'Email inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password Input
                AppTextField(
                  label: 'Password',
                  hint: '******',
                  controller: passwordController,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor insira a password';
                    }
                    if (value.length < 6) {
                      return 'A password deve ter pelo menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Submit Button
                AppPrimaryButton(
                  text: 'Entrar',
                  isLoading: authState.status == AuthStatus.loading,
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      ref.read(authControllerProvider.notifier).login(
                            emailController.text.trim(),
                            passwordController.text,
                          );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}