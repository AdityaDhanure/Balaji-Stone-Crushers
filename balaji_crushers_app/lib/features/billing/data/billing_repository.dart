import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class BillingRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<dynamic>> getInvoices({String? status, int? customerId, String? startDate, String? endDate}) async {
    try {
      final params = <String, dynamic>{};
      if (status != null) params['status'] = status;
      if (customerId != null) params['customerId'] = customerId;
      if (startDate != null) params['startDate'] = startDate;
      if (endDate != null) params['endDate'] = endDate;
      
      final response = await _apiClient.dio.get('/billing', queryParameters: params);
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to load invoices');
    }
  }

  Future<dynamic> getInvoiceById(int id) async {
    try {
      final response = await _apiClient.dio.get('/billing/$id');
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to load invoice');
    }
  }

  Future<dynamic> createInvoice(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/billing', data: data);
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to create invoice');
    }
  }

  Future<dynamic> updateInvoice(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('/billing/$id', data: data);
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to update invoice');
    }
  }

  Future<dynamic> updateInvoiceStatus(int id, String status) async {
    try {
      final response = await _apiClient.dio.patch('/billing/$id/status', data: {'status': status});
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to update status');
    }
  }

  Future<void> deleteInvoice(int id) async {
    try {
      await _apiClient.dio.delete('/billing/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to delete invoice');
    }
  }

  Future<String> getNextInvoiceNumber() async {
    try {
      final response = await _apiClient.dio.get('/billing/next-number');
      return response.data['invoice_number'];
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to get next number');
    }
  }

  Future<dynamic> getInvoiceStats() async {
    try {
      final response = await _apiClient.dio.get('/billing/stats');
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to load stats');
    }
  }

  Future<List<dynamic>> getItemsByInvoice(int invoiceId) async {
    try {
      final response = await _apiClient.dio.get('/billing/$invoiceId/items');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to load invoice items');
    }
  }

  Future<List<dynamic>> getPaymentHistory(int invoiceId) async {
    try {
      final response = await _apiClient.dio.get('/billing/$invoiceId/payments');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to load payment history');
    }
  }

  Future<dynamic> recordPayment(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/billing/payments', data: data);
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to record payment');
    }
  }
}
