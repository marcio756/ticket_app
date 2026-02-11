import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/data/models/user_model.dart';

final userListControllerProvider = 
    StateNotifierProvider.autoDispose<UserListController, AsyncValue<List<UserModel>>>((ref) {
  return UserListController();
});

/// Manages the state for the list of users (Admin/Support only).
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

  Future<bool> createUser(Map<String, dynamic> userData) async {
    try {
      await _apiClient.client.post('/users', data: userData);
      await loadUsers();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateUser(int id, Map<String, dynamic> userData) async {
    try {
      await _apiClient.client.put('/users/$id', data: userData);
      await loadUsers();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteUser(int userId, String adminPassword) async {
    try {
      // Enviar a password do admin no body do delete para validação
      await _apiClient.client.delete('/users/$userId', data: {'admin_password': adminPassword});
      await loadUsers(); 
      return true;
    } catch (e) {
      return false;
    }
  }
}