import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/user_list_controller.dart';
import 'user_form_screen.dart';
import '../../../../shared/components/inputs/app_text_field.dart';

class UserListScreen extends ConsumerStatefulWidget {
  const UserListScreen({super.key});

  @override
  ConsumerState<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends ConsumerState<UserListScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(userListControllerProvider.notifier).loadUsers(search: query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final usersState = ref.watch(userListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Utilizadores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserFormScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Pesquisar nome ou email...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged
            ),
          ),
          Expanded(
            child: usersState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Erro: $err')),
              data: (users) {
                if (users.isEmpty) {
                  return const Center(child: Text('Nenhum utilizador encontrado.'));
                }
                return ListView.separated(
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      leading: CircleAvatar(child: Text(user.name[0].toUpperCase())),
                      title: Text(user.name),
                      subtitle: Text('${user.email}\n${user.role}'),
                      isThreeLine: true,
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Editar'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'delete') {
                            _confirmDelete(context, ref, user.id);
                          } else if (value == 'edit') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserFormScreen(user: user),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, int userId) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Utilizador?'),
        content: SingleChildScrollView( 
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Esta ação não pode ser revertida. Insira a sua password para confirmar.'),
              const SizedBox(height: 16),
              AppTextField(
                controller: passwordController,
                label: 'A sua password',
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              passwordController.dispose();
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (passwordController.text.isEmpty) return;
              
              final pwd = passwordController.text;
              Navigator.pop(context);
              
              final messenger = ScaffoldMessenger.of(context);
              final success = await ref.read(userListControllerProvider.notifier).deleteUser(userId, pwd);
              
              if (!success) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Falha ao eliminar. Verifique a sua password ou as regras do sistema.'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}