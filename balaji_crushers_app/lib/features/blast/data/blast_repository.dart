import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';

dynamic _unwrap(dynamic res) {
  if (res is Map<String, dynamic> && res.containsKey('data')) {
    return res['data'];
  }
  return res;
}

class BlastRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<dynamic>> getAllBlasts() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.blasts);
      final data = _unwrap(response.data);

      if (data is List) return data;
      if (data is Map<String, dynamic>) {
        return data['items'] ?? [];
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load blasts');
    }
  }

  Future<Map<String, dynamic>> getBlastById(int id) async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.blasts}/$id');
      final data = _unwrap(response.data);

      if (data is Map<String, dynamic>) return data;
      return {};
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load blast details');
    }
  }

  Future<Map<String, dynamic>> createBlast(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post(ApiConstants.blasts, data: data);
      final resData = _unwrap(response.data);

      if (resData is Map<String, dynamic>) return resData;
      return {};
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to create blast');
    }
  }

  Future<Map<String, dynamic>> updateBlast(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('${ApiConstants.blasts}/$id', data: data);
      final resData = _unwrap(response.data);

      if (resData is Map<String, dynamic>) return resData;
      return {};
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to update blast');
    }
  }

  Future<void> deleteBlast(int id) async {
    try {
      await _apiClient.dio.delete('${ApiConstants.blasts}/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to delete blast');
    }
  }

  Future<int> getNextBlastNumber() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.blastNextNumber);
      final data = _unwrap(response.data);

      final numVal = data is Map<String, dynamic>
          ? data['next_number']
          : null;

      return int.tryParse(numVal?.toString() ?? '1') ?? 1;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to get next blast number');
    }
  }

  Future<Map<String, dynamic>?> getActiveBlast() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.blastActive);
      // The response envelope is { success: true, data: <blast|null> }.
      // We must look inside 'data' explicitly — _unwrap() is NOT safe here
      // because when data is null/undefined the envelope itself is a Map and
      // would be returned as the blast object, causing all fields to be null.
      final envelope = response.data;
      if (envelope is Map<String, dynamic> && envelope.containsKey('data')) {
        final inner = envelope['data'];
        if (inner is Map<String, dynamic> && inner.isNotEmpty) return inner;
        return null;
      }
      return null;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to get active blast');
    }
  }

  Future<void> completeBlast(int id) async {
    try {
      await _apiClient.dio.patch('${ApiConstants.blasts}/$id/complete');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to complete blast');
    }
  }

  Future<void> reopenBlast(int id) async {
    try {
      await _apiClient.dio.patch('${ApiConstants.blasts}/$id/reopen');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to reopen blast');
    }
  }

  Future<List<dynamic>> getVehicleTypes() async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.blasts}/vehicles/types');
      final data = _unwrap(response.data);

      if (data is List) return data;
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to get vehicle types');
    }
  }

  Future<List<dynamic>> getVehiclesByType(String type) async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.blasts}/vehicles/by-type/$type');
      final data = _unwrap(response.data);

      if (data is List) return data;
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to get vehicles');
    }
  }

  Future<List<dynamic>> getBlastTrips(int blastId) async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.blasts}/$blastId/trips');
      final data = _unwrap(response.data);

      if (data is List) return data;
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load trips');
    }
  }

  Future<Map<String, dynamic>> addTrip(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post(ApiConstants.blastTrips, data: data);
      final resData = _unwrap(response.data);

      if (resData is Map<String, dynamic>) return resData;
      return {};
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to add trip');
    }
  }

  Future<Map<String, dynamic>> updateTrip(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('${ApiConstants.blastTrips.replaceAll('/trips', '')}/trips/$id', data: data);
      final resData = _unwrap(response.data);

      if (resData is Map<String, dynamic>) return resData;
      return {};
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to update trip');
    }
  }

  Future<void> deleteTrip(int id) async {
    try {
      await _apiClient.dio.delete('${ApiConstants.blastTrips.replaceAll('/trips', '')}/trips/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to delete trip');
    }
  }

  Future<List<dynamic>> getTripsGroupedByDate(int blastId) async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.blasts}/$blastId/trips/by-date');
      final data = _unwrap(response.data);

      if (data is List) return data;
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load date-grouped trips');
    }
  }

  Future<List<dynamic>> getTripDates(int blastId) async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.blasts}/$blastId/trips/dates');
      final data = _unwrap(response.data);

      if (data is List) return data;
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load trip dates');
    }
  }

  Future<List<dynamic>> getBlastExpenses(int blastId) async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.blasts}/$blastId/expenses');
      final data = _unwrap(response.data);

      if (data is List) return data;
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load expenses');
    }
  }

  Future<Map<String, dynamic>> addExpense(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post(ApiConstants.blastExpenses, data: data);
      final resData = _unwrap(response.data);

      if (resData is Map<String, dynamic>) return resData;
      return {};
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to add expense');
    }
  }

  Future<void> deleteExpense(int id) async {
    try {
      await _apiClient.dio.delete('${ApiConstants.blastExpenses.replaceAll('/expenses', '')}/expenses/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to delete expense');
    }
  }

  Future<List<dynamic>> getExpensesGroupedByDate(int blastId) async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.blasts}/$blastId/expenses/by-date');
      final data = _unwrap(response.data);

      if (data is List) return data;
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load date-grouped expenses');
    }
  }

  Future<List<dynamic>> getExpenseDates(int blastId) async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.blasts}/$blastId/expenses/dates');
      final data = _unwrap(response.data);

      if (data is List) return data;
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load expense dates');
    }
  }

  Future<Map<String, dynamic>> updateExpense(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('${ApiConstants.blastExpenses.replaceAll('/expenses', '')}/expenses/$id', data: data);
      final resData = _unwrap(response.data);

      if (resData is Map<String, dynamic>) return resData;
      return {};
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to update expense');
    }
  }
}
