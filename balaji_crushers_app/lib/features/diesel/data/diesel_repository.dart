import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';

class DieselRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getStockOverview() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.dieselStock);
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load stock');
    }
  }

  Future<List<dynamic>> getAllPurchases() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.dieselPurchases);
      return response.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load purchases');
    }
  }

  Future<void> createPurchase(Map<String, dynamic> data) async {
    try {
      await _apiClient.dio.post(ApiConstants.dieselPurchases, data: data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to record purchase');
    }
  }

  Future<void> deletePurchase(int id) async {
    try {
      await _apiClient.dio.delete('${ApiConstants.dieselPurchases}/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to delete purchase');
    }
  }

  Future<void> markPurchasePaid(int id) async {
    try {
      await _apiClient.dio.put('${ApiConstants.dieselPurchases}/$id', data: {'payment_status': 'paid'});
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to update purchase');
    }
  }

  Future<List<dynamic>> getAllConsumption() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.dieselConsumption);
      return response.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load consumption');
    }
  }

  Future<void> createConsumption(Map<String, dynamic> data) async {
    try {
      await _apiClient.dio.post(ApiConstants.dieselConsumption, data: data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to record consumption');
    }
  }

  Future<void> deleteConsumption(int id) async {
    try {
      await _apiClient.dio.delete('${ApiConstants.dieselConsumption}/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to delete consumption');
    }
  }

  Future<void> updateConsumption(int id, Map<String, dynamic> data) async {
    try {
      await _apiClient.dio.put('${ApiConstants.dieselConsumption}/$id', data: data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to update consumption');
    }
  }

  Future<List<dynamic>> getConsumptionGroupedByDate() async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.dieselConsumption}/grouped');
      return response.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load grouped consumption');
    }
  }

  Future<List<dynamic>> getVehicleWiseConsumption({String? startDate, String? endDate}) async {
    try {
      final params = <String, dynamic>{};
      if (startDate != null) params['startDate'] = startDate;
      if (endDate != null) params['endDate'] = endDate;
      final response = await _apiClient.dio.get(ApiConstants.dieselVehicleWise, queryParameters: params);
      return response.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load vehicle consumption');
    }
  }

  Future<List<dynamic>> getPumpWisePayments() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.dieselPumpWise);
      return response.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load pump payments');
    }
  }

  Future<List<dynamic>> getVehicles() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.vehicles);
      return response.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load vehicles');
    }
  }
}
