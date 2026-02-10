import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/storage_service.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import 'auth_state.dart';

/// Provider global para aceder ao AuthController
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    authRemoteDataSource: AuthRemoteDataSourceImpl(),
    storageService: StorageService(),
  );
});

class AuthController extends StateNotifier<AuthState> {
  final AuthRemoteDataSource _authRemoteDataSource;
  final StorageService _storageService;

  AuthController({
    required AuthRemoteDataSource authRemoteDataSource,
    required StorageService storageService,
  })  : _authRemoteDataSource = authRemoteDataSource,
        _storageService = storageService,
        super(const AuthState());

  /// Verifica se já existe um token guardado ao iniciar a app
  Future<void> checkAuthStatus() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final token = await _storageService.getToken();
      if (token != null) {
        // Opcional: Validar o token batendo na API /user ou assumir válido
        // Aqui vamos buscar o perfil para garantir que o token funciona
        final user = await _authRemoteDataSource.getUserProfile();
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      // Se o token for inválido (401), apagamos
      await _storageService.deleteToken();
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  /// Realiza o login
  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final result = await _authRemoteDataSource.login(email, password);
      
      final user = result['user'];
      final token = result['token'];

      // Guarda o token no telemóvel
      await _storageService.saveToken(token);

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.failure,
        errorMessage: 'Falha no login. Verifique as credenciais.',
      );
    }
  }

  /// Realiza o logout
  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _authRemoteDataSource.logout();
    } catch (_) {
      // Ignora erro de rede no logout, forçamos o logout local
    } finally {
      await _storageService.deleteToken();
      state = state.copyWith(status: AuthStatus.unauthenticated, user: null);
    }
  }
}