import 'package:dio/dio.dart';
import 'package:balaji_crushers_app/core/network/api_client.dart';
import '../models/expense_models.dart';

class ExpenseRepository {
  final ApiClient _api = ApiClient();

  // ─── Categories ────────────────────────────────────────────────────────────

  Future<List<ExpenseCategory>> getCategories({bool activeOnly = true}) async {
    try {
      final res = await _api.dio.get(
        '/expenses/categories',
        queryParameters: {'active': activeOnly},
      );
      if (res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 300) {
        final data = _unwrap(res.data);

        return (data as List)
            .map((e) => ExpenseCategory.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Failed to load categories');
    } on DioException catch (e) {
      throw Exception(_errorMsg(e));
    }
  }

  Future<ExpenseCategory> createCategory(ExpenseCategory category) async {
    try {
      final res = await _api.dio.post('/expenses/categories', data: {
        'name': category.name,
        'description': category.description ?? '',
        'icon': category.icon,
        'color': category.color,
      });
      if (res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 300) {
        final data = _unwrap(res.data);
        return ExpenseCategory.fromJson(data as Map<String, dynamic>);
      }
      throw Exception('Failed to create category');
    } on DioException catch (e) {
      throw Exception(_errorMsg(e));
    }
  }

  // ─── Manual Expenses ───────────────────────────────────────────────────────

  Future<List<Expense>> getExpenses({
    int? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    int? limit,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (categoryId != null) params['category_id'] = categoryId;
      if (startDate != null)  params['start_date']  = _fmt(startDate);
      if (endDate != null)    params['end_date']     = _fmt(endDate);
      if (status != null)     params['status']       = status;
      if (limit != null)      params['limit']        = limit;

      final res = await _api.dio.get('/expenses', queryParameters: params);
      if (res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 300) {
        final data = _unwrap(res.data);

        return (data as List)
            .map((e) => Expense.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Failed to load expenses');
    } on DioException catch (e) {
      throw Exception(_errorMsg(e));
    }
  }

  Future<Expense> getExpense(int id) async {
    try {
      final res = await _api.dio.get('/expenses/$id');
      if (res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 300) {
        final data = _unwrap(res.data);
        return Expense.fromJson(data as Map<String, dynamic>);
      }
      throw Exception('Failed to load expense');
    } on DioException catch (e) {
      throw Exception(_errorMsg(e));
    }
  }

  Future<Expense> createExpense(Expense expense) async {
    try {
      final data = <String, dynamic>{
        'category_id':     expense.categoryId,
        'expense_date':    _fmt(expense.expenseDate),
        'amount':          expense.amount,
        'payment_mode':    expense.paymentMode,
        'vendor_name':     expense.vendorName ?? '',
        'description':     expense.description ?? '',
        'reference_number': expense.referenceNumber ?? '',
        'status':          expense.status,
      };
      final res = await _api.dio.post('/expenses', data: data);
      if (res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 300) {
        final data = _unwrap(res.data);
        return Expense.fromJson(data as Map<String, dynamic>);
      }
      throw Exception('Failed to create expense');
    } on DioException catch (e) {
      throw Exception(_errorMsg(e));
    }
  }

  Future<Expense> updateExpense(int id, Map<String, dynamic> data) async {
    try {
      final res = await _api.dio.patch('/expenses/$id', data: data);
      if (res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 300) {
        final data = _unwrap(res.data);
        return Expense.fromJson(data as Map<String, dynamic>);
      }
      throw Exception('Failed to update expense');
    } on DioException catch (e) {
      throw Exception(_errorMsg(e));
    }
  }

  Future<void> deleteExpense(int id) async {
    try {
      final res = await _api.dio.delete('/expenses/$id');
      if (res.statusCode == null || res.statusCode! < 200 || res.statusCode! >= 300) {
        throw Exception('Failed to delete expense');
      }
    } on DioException catch (e) {
      throw Exception(_errorMsg(e));
    }
  }

  Future<void> approveExpense(int id) async {
    try {
      final res = await _api.dio.patch('/expenses/$id/approve');
      if (res.statusCode == null || res.statusCode! < 200 || res.statusCode! >= 300) {
        throw Exception('Failed to approve expense');
      }
    } on DioException catch (e) {
      throw Exception(_errorMsg(e));
    }
  }

  Future<String> getNextExpenseNumber() async {
    try {
      final res = await _api.dio.get('/expenses/next-number');
      if (res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 300) {
        final data = _unwrap(res.data);
        return data['expense_number'];
      }
      throw Exception('Failed to get next number');
    } on DioException catch (e) {
      throw Exception(_errorMsg(e));
    }
  }

  // ─── Unified (all 9 sources) ───────────────────────────────────────────────

  Future<List<UnifiedExpense>> getUnifiedExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? type,
    int? limit,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (startDate != null) params['start_date'] = _fmt(startDate);
      if (endDate != null)   params['end_date']   = _fmt(endDate);
      if (type != null)      params['type']        = type;
      if (limit != null)     params['limit']       = limit;

      final res = await _api.dio.get('/expenses/unified', queryParameters: params);
      if (res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 300) {
        final data = _unwrap(res.data);

        return (data as List)
            .map((e) => UnifiedExpense.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Failed to load unified expenses');
    } on DioException catch (e) {
      throw Exception(_errorMsg(e));
    }
  }

  Future<UnifiedExpenseSummary> getExpenseSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (startDate != null) params['start_date'] = _fmt(startDate);
      if (endDate != null)   params['end_date']   = _fmt(endDate);

      final res = await _api.dio.get('/expenses/summary', queryParameters: params);
      if (res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 300) {
        final data = _unwrap(res.data);

        return UnifiedExpenseSummary.fromJson(data as Map<String, dynamic>);
      }
      throw Exception('Failed to load expense summary');
    } on DioException catch (e) {
      throw Exception(_errorMsg(e));
    }
  }

  dynamic _unwrap(dynamic res) {
    if (res is Map<String, dynamic> && res.containsKey('data')) {
      return res['data'];
    }
    return res;
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  String _fmt(DateTime dt) {
    final local = dt.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _errorMsg(DioException e) {
    if (e.response?.statusCode == 401) return 'Unauthorized. Please login again.';
    return e.message ?? 'An error occurred';
  }
}
