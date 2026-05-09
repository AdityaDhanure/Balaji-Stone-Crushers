import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class EmployeeRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<dynamic>> getEmployees({bool isActive = true}) async {
    try {
      final response = await _apiClient.dio.get('/employees', queryParameters: {'isActive': isActive.toString()});
      final data = response.data is List ? response.data as List : response.data['data'] as List;
      return data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to load employees');
    }
  }

  Future<List<dynamic>> getAllEmployees() async {
    try {
      final response = await _apiClient.dio.get('/employees/all');
      final data = response.data is List ? response.data as List : response.data['data'] as List;
      return data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to load employees');
    }
  }

  Future<dynamic> getEmployeeById(int id) async {
    try {
      final response = await _apiClient.dio.get('/employees/$id');
      return response.data['data'] ?? response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to load employee');
    }
  }

  Future<dynamic> createEmployee(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/employees', data: data);
      return response.data['data'] ?? response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to create employee');
    }
  }

  Future<dynamic> updateEmployee(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('/employees/$id', data: data);
      return response.data['data'] ?? response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to update employee');
    }
  }

  Future<void> deleteEmployee(int id) async {
    try {
      await _apiClient.dio.delete('/employees/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to delete employee');
    }
  }

  Future<String> getNextEmployeeCode() async {
    try {
      final response = await _apiClient.dio.get('/employees/next-code');
      return response.data['employee_code'];
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to get next code');
    }
  }

  Future<dynamic> getEmployeeStats() async {
    try {
      final response = await _apiClient.dio.get('/employees/stats');
      return response.data['data'] ?? response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to load stats');
    }
  }

  Future<List<dynamic>> getDepartments() async {
    try {
      final response = await _apiClient.dio.get('/employees/departments');
      final data = response.data is List ? response.data as List : response.data['data'] as List;
      return data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to load departments');
    }
  }

  Future<List<dynamic>> getPendingLeaves() async {
    try {
      final response = await _apiClient.dio.get('/employees/leaves/pending');
      final data = response.data is List ? response.data as List : response.data['data'] as List;
      return data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to load pending leaves');
    }
  }

  Future<void> approveLeave(int id) async {
    try {
      await _apiClient.dio.patch('/employees/leaves/$id/status', data: {'status': 'approved'});
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to approve leave');
    }
  }

  Future<void> rejectLeave(int id) async {
    try {
      await _apiClient.dio.patch('/employees/leaves/$id/status', data: {'status': 'rejected'});
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to reject leave');
    }
  }
}
