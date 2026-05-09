import 'package:dio/dio.dart';
import 'package:balaji_crushers_app/core/network/api_client.dart';

class AuthRepository {
  final Dio _dio = ApiClient().dio;

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        return {
          'token': data['token'],
          ...data['user'] as Map<String, dynamic>,
        };
      }
      throw Exception(response.data['message'] ?? 'Login failed');
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['message'] ?? 'Login error');
      }
      rethrow;
    }
  }

  /// Validate the stored token and return the current user profile.
  /// Returns null if the token is missing or expired (used at app startup).
  Future<Map<String, dynamic>?> getMe() async {
    try {
      final response = await _dio.get('/auth/me');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Fetch the full profile from /auth/me and THROW on any error.
  /// Used by refreshProfile so errors are surfaced to the UI.
  Future<Map<String, dynamic>> fetchProfile() async {
    try {
      final response = await _dio.get('/auth/me');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      }
      throw Exception(response.data['message'] ?? 'Failed to load profile');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Failed to load profile',
      );
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (e) {
      // Ignore logout errors
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/auth/profile', data: data);
      if (response.data['success'] == true) {
        return response.data['data']['user'] as Map<String, dynamic>;
      }
      throw Exception(response.data['message'] ?? 'Failed to update profile');
    } on DioException catch (e) {
      final msg = e.response?.data?['message']
          ?? e.message
          ?? 'Failed to update profile';
      throw Exception(msg);
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final response = await _dio.put(
        '/auth/change-password',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to change password');
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data?['message'] ?? 'Failed to change password');
      }
      rethrow;
    }
  }
}

