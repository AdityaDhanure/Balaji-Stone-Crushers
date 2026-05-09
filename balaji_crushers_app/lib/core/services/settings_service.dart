import 'package:dio/dio.dart';
import '../network/api_client.dart';

class SettingsService {
  // Use the app-wide ApiClient singleton so the auth interceptor
  // automatically attaches the Bearer token on every request.
  final Dio _dio = ApiClient().dio;

  Future<Map<String, String>> getAllSettings() async {
    try {
      final response = await _dio.get('/settings', queryParameters: {'format': 'map'});
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return Map<String, String>.from(data['data']);
        }
        throw Exception(data['message'] ?? 'Failed to load settings');
      }
      throw Exception('Failed to load settings: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  Future<Map<String, dynamic>> getSettingByKey(String key) async {
    try {
      final response = await _dio.get('/settings/$key');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return data['data'];
        }
        throw Exception(data['message'] ?? 'Failed to load setting');
      }
      if (response.statusCode == 404) {
        throw Exception('Setting not found');
      }
      throw Exception('Failed to load setting: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  Future<Map<String, dynamic>> updateSetting(String key, String value) async {
    try {
      final response = await _dio.patch('/settings', data: {'key': key, 'value': value});
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Failed to update setting');
        }
        return data['data'];
      }
      throw Exception('Failed to update setting: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  Future<BulkUpdateResult> bulkUpdateSettings(Map<String, String> settings) async {
    try {
      final settingsList = settings.entries
          .map((e) => {'key': e.key, 'value': e.value})
          .toList();

      final response = await _dio.post('/settings/bulk', data: {'settings': settingsList});
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return BulkUpdateResult(
            updatedCount: (data['data']['updated'] as List?)?.length ?? 0,
            errors: (data['data']['errors'] as List?) ?? [],
          );
        }
        throw Exception(data['message'] ?? 'Failed to save settings');
      }
      throw Exception('Failed to save settings: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  Future<Map<String, dynamic>> exportSettings() async {
    try {
      final response = await _dio.get('/settings/export');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return data['data'];
        }
        throw Exception(data['message'] ?? 'Failed to export settings');
      }
      throw Exception('Failed to export settings: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  Future<void> importSettings(Map<String, dynamic> importData) async {
    try {
      final response = await _dio.post('/settings/import', data: importData);
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Failed to import settings');
        }
        return;
      }
      throw Exception('Failed to import settings: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  Future<void> resetToDefaults() async {
    try {
      final response = await _dio.post('/settings/reset');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Failed to reset settings');
        }
        return;
      }
      throw Exception('Failed to reset settings: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  String _handleDioError(DioException e) {
    if (e.response != null) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'];
      }
      if (e.response?.statusCode == 401) {
        return 'Unauthorized. Please login again.';
      }
      return 'Server error: ${e.response?.statusCode}';
    }
    if (e.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout. Please check your internet.';
    }
    if (e.type == DioExceptionType.receiveTimeout) {
      return 'Server not responding. Please try again.';
    }
    return 'Network error. Please check your connection.';
  }
}

class BulkUpdateResult {
  final int updatedCount;
  final List<dynamic> errors;

  BulkUpdateResult({required this.updatedCount, required this.errors});
}
