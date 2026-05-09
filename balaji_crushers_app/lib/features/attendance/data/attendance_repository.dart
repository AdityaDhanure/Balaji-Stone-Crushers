import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';

dynamic _unwrap(dynamic res) {
  if (res is Map<String, dynamic> && res.containsKey('data')) {
    return res['data'];
  }
  return res;
}

class AttendanceRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<dynamic>> getAttendance({String? date, String? startDate, String? endDate, int? employeeId}) async {
    try {
      final params = <String, dynamic>{};
      if (date != null) params['date'] = date;
      if (startDate != null) params['startDate'] = startDate;
      if (endDate != null) params['endDate'] = endDate;
      if (employeeId != null) params['employeeId'] = employeeId;
      final response = await _apiClient.dio.get('/attendance', queryParameters: params);
      final data = _unwrap(response.data);
      return data as List? ?? [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to load attendance');
    }
  }

  Future<List<dynamic>> getAttendanceByDate(String date) async {
    try {
      final response = await _apiClient.dio.get('/attendance/by-date/$date');
      final data = _unwrap(response.data);
      return data as List? ?? [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to load attendance');
    }
  }

  Future<dynamic> markAttendance(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/attendance', data: data);
      return _unwrap(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to mark attendance');
    }
  }

  Future<Map<String, dynamic>> bulkMarkAttendance(List<Map<String, dynamic>> records) async {
    try {
      final response = await _apiClient.dio.post('/attendance/bulk', data: {'records': records});
      return _unwrap(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to save attendance');
    }
  }

  Future<dynamic> updateAttendance(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('/attendance/$id', data: data);
      return _unwrap(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to update attendance');
    }
  }

  Future<void> deleteAttendance(int id) async {
    try {
      await _apiClient.dio.delete('/attendance/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to delete attendance');
    }
  }

  /// Deletes ALL attendance records for a given date (YYYY-MM-DD).
  Future<Map<String, dynamic>> deleteAllByDate(String date) async {
    try {
      final response = await _apiClient.dio.delete('/attendance/by-date/$date');
      return response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : {};
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to delete attendance for $date');
    }
  }

  Future<dynamic> getDailySummary(String date) async {
    try {
      final response = await _apiClient.dio.get('/attendance/summary/daily', queryParameters: {'date': date});
      return _unwrap(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to load summary');
    }
  }

  Future<List<dynamic>> getShifts() async {
    try {
      final response = await _apiClient.dio.get('/attendance/shifts');
      final data = _unwrap(response.data);
      return data as List? ?? [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to load shifts');
    }
  }

  Future<Map<String, dynamic>> getPaidLeaveBalance(int employeeId) async {
    try {
      final response = await _apiClient.dio.get('/attendance/leave-balance/$employeeId');
      final data = _unwrap(response.data);
      return data is Map<String, dynamic> ? data : {};
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to load leave balance');
    }
  }
}
