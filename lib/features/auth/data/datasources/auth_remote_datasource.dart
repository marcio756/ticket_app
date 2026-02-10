import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';

/// Interface for remote authentication operations.
abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login(String email, String password);
  Future<UserModel> getUserProfile();
  Future<void> logout();
}

/// Implementation of AuthRemoteDataSource using Dio.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSourceImpl({ApiClient? apiClient}) 
      : _apiClient = apiClient ?? ApiClient();

  @override
  /// Authenticates the user with email and password.
  /// Returns a map containing the 'user' (UserModel) and 'token' (String).
  ///
  /// @throws DioException if the request fails.
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiClient.client.post('/login', data: {
        'email': email,
        'password': password,
      });

      // Assumindo que AuthApiController retorna: {'data': {'user': ..., 'token': ...}}
      // ou diretamente {'user': ..., 'token': ...}. Ajustar conforme o teu return do Laravel.
      final data = response.data;
      
      // Ajuste baseado no padrão comum de Resources do Laravel (que envolvem em 'data')
      // Se o teu AuthApiController não usar Resource::collection para login, pode ser direto.
      final user = UserModel.fromJson(data['user']); 
      final token = data['token'];

      return {
        'user': user,
        'token': token,
      };
    } catch (e) {
      rethrow;
    }
  }

  @override
  /// Fetches the current authenticated user's profile.
  Future<UserModel> getUserProfile() async {
    final response = await _apiClient.client.get('/user');
    return UserModel.fromJson(response.data['data']); // UserResource normalmente embrulha em 'data'
  }

  @override
  /// Revokes the current access token.
  Future<void> logout() async {
    await _apiClient.client.post('/logout');
  }
}