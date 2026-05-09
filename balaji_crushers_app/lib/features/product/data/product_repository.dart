import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class ProductRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<dynamic>> getProducts() async {
    try {
      final response = await _apiClient.dio.get('/products');
      return response.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to load products');
    }
  }

  Future<List<dynamic>> getActiveProducts() async {
    try {
      final response = await _apiClient.dio.get('/products/active');
      return response.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to load active products');
    }
  }

  Future<dynamic> getProductById(int id) async {
    try {
      final response = await _apiClient.dio.get('/products/$id');
      return response.data['data'];
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to load product');
    }
  }

  Future<dynamic> createProduct(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/products', data: data);
      return response.data['data'];
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to create product');
    }
  }

  Future<dynamic> updateProduct(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('/products/$id', data: data);
      return response.data['data'];
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to update product');
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      await _apiClient.dio.delete('/products/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to delete product');
    }
  }

  Future<String> getNextProductCode() async {
    try {
      final response = await _apiClient.dio.get('/products/next-code');
      return response.data['product_code'];
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to get next code');
    }
  }

  Future<List<dynamic>> getCategories() async {
    try {
      final response = await _apiClient.dio.get('/products/categories/all');
      return response.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to load categories');
    }
  }

  Future<dynamic> createCategory(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/products/categories', data: data);
      return response.data['data'];
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to create category');
    }
  }

  Future<List<dynamic>> getProduction({String? startDate, String? endDate, int? productId}) async {
    try {
      final params = <String, dynamic>{};
      if (startDate != null) params['startDate'] = startDate;
      if (endDate != null) params['endDate'] = endDate;
      if (productId != null) params['productId'] = productId;
      
      final response = await _apiClient.dio.get('/products/production/', queryParameters: params);
      return response.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to load production');
    }
  }

  Future<dynamic> createProduction(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/products/production', data: data);
      return response.data['data'];
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to create production');
    }
  }

  Future<dynamic> updateProduction(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('/products/production/$id', data: data);
      return response.data['data'];
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to update production');
    }
  }

  Future<void> deleteProduction(int id) async {
    try {
      await _apiClient.dio.delete('/products/production/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to delete production');
    }
  }

  Future<dynamic> getDailySummary(String date) async {
    try {
      final response = await _apiClient.dio.get('/products/production/daily/$date');
      return response.data['data'];
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to load daily summary');
    }
  }

  Future<List<dynamic>> getProductionGroupedByDate() async {
    try {
      final response = await _apiClient.dio.get('/products/production/grouped');
      return response.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to load grouped production');
    }
  }
}
