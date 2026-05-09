import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class CustomerRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<dynamic>> getCustomers() async {
    try {
      final response = await _apiClient.dio.get('/customers');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to load customers');
    }
  }

  Future<List<dynamic>> getActiveCustomers() async {
    try {
      final response = await _apiClient.dio.get('/customers/active');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to load active customers');
    }
  }

  Future<dynamic> getCustomerById(int id) async {
    try {
      final response = await _apiClient.dio.get('/customers/$id');
      return response.data['data'];
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to load customer');
    }
  }

  Future<dynamic> createCustomer(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/customers', data: data);
      return response.data['data'];
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to create customer');
    }
  }

  Future<dynamic> updateCustomer(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('/customers/$id', data: data);
      return response.data['data'];
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to update customer');
    }
  }

  Future<void> deleteCustomer(int id) async {
    try {
      await _apiClient.dio.delete('/customers/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to delete customer');
    }
  }

  Future<String> getNextCustomerCode() async {
    try {
      final response = await _apiClient.dio.get('/customers/next-code');
      return response.data['customer_code'];
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to get next code');
    }
  }

  Future<List<dynamic>> searchCustomers(String query) async {
    try {
      final response = await _apiClient.dio.get('/customers/search', queryParameters: {'q': query});
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to search customers');
    }
  }

  Future<Map<String, dynamic>> getWalletData(int customerId) async {
    try {
      final response = await _apiClient.dio.get('/customers/$customerId/wallet');
      return response.data['data'];
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to load wallet data');
    }
  }

  Future<dynamic> addWalletTransaction(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/customers/wallet/transactions', data: data);
      return response.data['data'];
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to add transaction');
    }
  }
}
