import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';

dynamic _unwrap(dynamic res) {
  if (res is Map<String, dynamic> && res.containsKey('data')) {
    return res['data'];
  }
  return res;
}

class VehicleRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<dynamic>> getAllVehicles() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.vehicles);
      final data = _unwrap(response.data);

      if (data is List) return data;
      if (data is Map<String, dynamic>) {
        return data['items'] ?? [];
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load vehicles');
    }
  }

  Future<Map<String, dynamic>> getVehicleById(int id) async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.vehicles}/$id');
      final data = _unwrap(response.data);

      if (data is Map<String, dynamic>) return data;
      return {};
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load vehicle details');
    }
  }

  Future<Map<String, dynamic>> createVehicle(Map<String, dynamic> body) async {
    final response = await _apiClient.dio.post(
      ApiConstants.vehicles,
      data: body,
    );

    final resData = _unwrap(response.data);

    if (resData is Map<String, dynamic>) return resData;
    return {};
  }

  Future<Map<String, dynamic>> updateVehicle(int id, Map<String, dynamic> body) async {
    final response = await _apiClient.dio.put(
      '${ApiConstants.vehicles}/$id',
      data: body,
    );

    final resData = _unwrap(response.data);

    if (resData is Map<String, dynamic>) return resData;
    return {};
  }

  Future<void> deleteVehicle(int id) async {
    try {
      await _apiClient.dio.delete('${ApiConstants.vehicles}/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to delete vehicle');
    }
  }

  Future<List<dynamic>> getUpcomingExpiries() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.vehicleExpiries);
      final data = _unwrap(response.data);

      if (data is List) return data;
      if (data is Map<String, dynamic>) {
        return data['items'] ?? [];
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load expiring documents');
    }
  }

  Future<List<dynamic>> getVehicleUsage(int vehicleId) async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.vehicles}/$vehicleId/usage');
      final data = _unwrap(response.data);

      if (data is List) return data;
      if (data is Map<String, dynamic>) {
        return data['items'] ?? [];
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load usage records');
    }
  }

  Future<List<dynamic>> getUsageGroupedByDate(int vehicleId) async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.vehicles}/$vehicleId/usage/by-date');
      final data = _unwrap(response.data);

      if (data is List) return data;
      if (data is Map<String, dynamic>) {
        return data['items'] ?? [];
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load date-grouped usage');
    }
  }

  Future<List<dynamic>> getUsageDates(int vehicleId) async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.vehicles}/$vehicleId/usage/dates');
      final data = _unwrap(response.data);

      if (data is List) return data;
      if (data is Map<String, dynamic>) {
        return data['items'] ?? [];
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load usage dates');
    }
  }

  Future<Map<String, dynamic>> addUsage(Map<String, dynamic> body) async {
    final response = await _apiClient.dio.post(
      ApiConstants.vehicleUsage,
      data: body,
    );

    final resData = _unwrap(response.data);

    if (resData is Map<String, dynamic>) return resData;
    return {};
  }

  Future<Map<String, dynamic>> updateUsage(int id, Map<String, dynamic> body) async {
    final response = await _apiClient.dio.put(
      '${ApiConstants.vehicleUsage.replaceAll('/usage', '')}/usage/$id',
      data: body,
    );

    final resData = _unwrap(response.data);

    if (resData is Map<String, dynamic>) return resData;
    return {};
  }

  Future<void> deleteUsage(int id) async {
    try {
      await _apiClient.dio.delete('${ApiConstants.vehicleUsage.replaceAll('/usage', '')}/usage/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to delete usage record');
    }
  }

  Future<void> updateOdometer(int id, double reading) async {
    try {
      await _apiClient.dio.patch('${ApiConstants.vehicles}/$id/odometer', data: {'reading': reading});
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to update odometer');
    }
  }
}
