import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/data/models/user_model.dart';

final userListControllerProvider = 
    StateNotifierProvider.autoDispose<UserListController, AsyncValue<List<UserModel>>>((ref) {
  return UserListController();
});

class UserListController extends StateNotifier<AsyncValue<List<UserModel>>> {
  UserListController() : super(const AsyncValue.loading()) {
    loadUsers();
  }

  final _apiClient = ApiClient();

  Future<void> loadUsers({String? search}) async {
    try {
      final response = await _apiClient.client.get(
        '/users',
        queryParameters: search != null ? {'search': search} : null,
      );
      
      final List data = response.data['data'] ?? response.data;
      final users = data.map((e) => UserModel.fromJson(e)).toList();
      
      state = AsyncValue.data(users);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // --- NOVO: Criar Utilizador ---
  Future<bool> createUser(Map<String, dynamic> userData) async {
    try {
      await _apiClient.client.post('/users', data: userData);
      await loadUsers(); // Atualiza a lista
      return true;
    } catch (e) {
      // Podes adicionar tratamento de erro mais específico aqui (ex: email duplicado)
      return false;
    }
  }

  // --- NOVO: Editar Utilizador ---
  Future<bool> updateUser(int id, Map<String, dynamic> userData) async {
    try {
      await _apiClient.client.put('/users/$id', data: userData);
      await loadUsers(); // Atualiza a lista
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteUser(int userId) async {
    try {
      await _apiClient.client.delete('/users/$userId');
      await loadUsers(); 
      return true;
    } catch (e) {
      return false;
    }
  }
}