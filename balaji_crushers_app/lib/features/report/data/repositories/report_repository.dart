import 'package:dio/dio.dart';
import 'package:balaji_crushers_app/core/network/api_client.dart';

dynamic _unwrap(dynamic res) {
  if (res is Map<String, dynamic> && res.containsKey('data')) {
    return res['data'];
  }
  return res;
}

class ReportRepository {
  final ApiClient _api = ApiClient();

  // ─── 1. Overview ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getOverviewSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final res = await _api.dio.get('/reports/overview', queryParameters: {
        'start_date': _fmt(startDate),
        'end_date':   _fmt(endDate),
      });
      final data = _unwrap(res.data);
      return data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_err(e));
    }
  }

  // ─── 2. Sales ────────────────────────────────────────────────────────────────

  Future<List<dynamic>> getSalesReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final res = await _api.dio.get('/reports/sales', queryParameters: {
        'start_date': _fmt(startDate),
        'end_date':   _fmt(endDate),
      });
      final data = _unwrap(res.data);
      if (data is List) {
        return data;
      } else if (data is Map<String, dynamic>) {
        return data['items'] ?? []; // fallback if wrapped
      } else {
        return [];
      }
    } on DioException catch (e) {
      throw Exception(_err(e));
    }
  }

  // ─── 3. Expense Summary ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getExpenseSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final res = await _api.dio.get('/reports/expense-summary', queryParameters: {
        'start_date': _fmt(startDate),
        'end_date':   _fmt(endDate),
      });
      final data = _unwrap(res.data);
      return data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_err(e));
    }
  }

  // ─── 4. Profit/Loss ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getProfitLoss({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final res = await _api.dio.get('/reports/profit-loss', queryParameters: {
        'start_date': _fmt(startDate),
        'end_date':   _fmt(endDate),
      });
      final data = _unwrap(res.data);
      return data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_err(e));
    }
  }

  // ─── 5. Yearly Trend ─────────────────────────────────────────────────────────

  Future<List<dynamic>> getYearlyTrend(int year) async {
    try {
      final res = await _api.dio.get('/reports/yearly-trend',
          queryParameters: {'year': year});
      final data = _unwrap(res.data);
      if (data is List) {
        return data;
      } else if (data is Map<String, dynamic>) {
        return data['items'] ?? []; // fallback if wrapped
      } else {
        return [];
      }
    } on DioException catch (e) {
      throw Exception(_err(e));
    }
  }

  String _fmt(DateTime d) {
    final local = d.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _err(DioException e) =>
      e.response?.data?['message'] as String? ??
      e.message ??
      'Failed to load report';
}
