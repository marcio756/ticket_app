import 'dart:io';
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

/// Gere o estado de autenticação e sessão do utilizador logado.
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
        final user = await _authRemoteDataSource.getUserProfile();
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
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
    } finally {
      await _storageService.deleteToken();
      state = state.copyWith(status: AuthStatus.unauthenticated, user: null);
    }
  }

  /// Atualiza o perfil do utilizador (comunica com a API e altera o estado atual)
  Future<bool> updateProfile(String name, String email, {File? avatar, String? currentPassword, String? newPassword, String? newPasswordConfirmation}) async {
    try {
      final updatedUser = await _authRemoteDataSource.updateProfile(
        name, 
        email, 
        avatar: avatar,
        currentPassword: currentPassword,
        newPassword: newPassword,
        newPasswordConfirmation: newPasswordConfirmation,
      );
      state = state.copyWith(user: updatedUser);
      return true;
    } catch (e) {
      return false;
    }
  }
}