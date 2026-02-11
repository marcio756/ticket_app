import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';

/// Interface for remote authentication operations.
abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login(String email, String password);
  Future<UserModel> getUserProfile();
  Future<void> logout();
  Future<UserModel> updateProfile(String name, String email, {File? avatar, String? currentPassword, String? newPassword, String? newPasswordConfirmation});
}

/// Implementation of AuthRemoteDataSource using Dio.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSourceImpl({ApiClient? apiClient}) 
      : _apiClient = apiClient ?? ApiClient();

  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiClient.client.post('/login', data: {
        'email': email,
        'password': password,
      });

      final data = response.data;
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
  Future<UserModel> getUserProfile() async {
    final response = await _apiClient.client.get('/user');
    return UserModel.fromJson(response.data['data']);
  }

  @override
  Future<void> logout() async {
    await _apiClient.client.post('/logout');
  }

  @override
  Future<UserModel> updateProfile(String name, String email, {File? avatar, String? currentPassword, String? newPassword, String? newPasswordConfirmation}) async {
    try {
      final formData = FormData.fromMap({
        'name': name,
        'email': email,
        if (avatar != null) 'avatar': await MultipartFile.fromFile(avatar.path),
        if (currentPassword != null && currentPassword.isNotEmpty) 'current_password': currentPassword,
        if (newPassword != null && newPassword.isNotEmpty) 'password': newPassword,
        if (newPasswordConfirmation != null && newPasswordConfirmation.isNotEmpty) 'password_confirmation': newPasswordConfirmation,
      });

      final response = await _apiClient.client.post('/user/profile', data: formData);
      
      return UserModel.fromJson(response.data['user']);
    } catch (e) {
      rethrow;
    }
  }
}