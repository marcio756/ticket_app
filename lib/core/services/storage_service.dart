import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service responsible for persisting sensitive data locally on the device.
/// Uses the Singleton pattern to ensure a single instance access.
class StorageService {
  static final StorageService _instance = StorageService._internal();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  factory StorageService() {
    return _instance;
  }

  StorageService._internal();

  static const String _tokenKey = 'auth_token';

  /// Saves the authentication token securely.
  ///
  /// @param token The JWT/Sanctum token string to be saved.
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Retrieves the stored authentication token.
  ///
  /// @return The token string or null if not found.
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Removes the stored authentication token (used for logout).
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }
  
  /// Checks if a valid token exists.
  ///
  /// @return True if a token exists, False otherwise.
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}