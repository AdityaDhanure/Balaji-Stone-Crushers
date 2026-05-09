import 'package:dio/dio.dart';
import 'package:balaji_crushers_app/core/network/api_client.dart';
import 'package:balaji_crushers_app/core/constants/api_constants.dart';
import '../models/salary_models.dart';
import 'package:intl/intl.dart';

dynamic _unwrap(dynamic res) {
  if (res is Map<String, dynamic> && res.containsKey('data')) {
    return res['data'];
  }
  return res;
}

class SalaryRepository {
  final _baseUrl = ApiConstants.baseUrl;

  Dio get _dio => ApiClient().dio;

  Future<List<SalaryPeriod>> getPeriods() async {
    try {
      final response = await _dio.get('$_baseUrl/salary/periods');
      final data = _unwrap(response.data);
      return (data as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((e) => SalaryPeriod.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data is Map
      ? e.response?.data['message']
      : e.message ?? 'Failed to load periods');
    }
  }

  Future<SalaryPeriod> createPeriod(int year, int month) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/salary/periods',
        data: {'year': year, 'month': month},
      );
      final data = _unwrap(response.data);
      return SalaryPeriod.fromJson(data);
    } on DioException catch (e) {
      throw Exception(e.response?.data is Map
      ? e.response?.data['message']
      : e.message ?? 'Failed to create period');
    }
  }

  Future<void> lockPeriod(int id, bool isLocked) async {
    try {
      await _dio.patch(
        '$_baseUrl/salary/periods/$id/lock',
        data: {'is_locked': isLocked},
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data is Map
      ? e.response?.data['message']
      : e.message ?? 'Failed to lock period');
    }
  }

  Future<List<EmployeeSalary>> getEmployees({bool activeOnly = true}) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/salary/employees',
        queryParameters: {'active': activeOnly},
      );
      final data = _unwrap(response.data);
      return (data as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((e) => EmployeeSalary.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data is Map
      ? e.response?.data['message']
      : e.message ?? 'Failed to load employees');
    }
  }

  Future<List<SalarySlip>> getSalarySlips({
    int? periodId,
    int? employeeId,
    String? status,
    int? departmentId,
  }) async {
    final params = <String, dynamic>{};
    if (periodId != null) params['period_id'] = periodId;
    if (employeeId != null) params['employee_id'] = employeeId;
    if (status != null) params['status'] = status;
    if (departmentId != null) params['department_id'] = departmentId;

    try {
      final response = await _dio.get('$_baseUrl/salary/slips', queryParameters: params);
      final data = _unwrap(response.data);
      return (data as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((e) => SalarySlip.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data is Map
      ? e.response?.data['message']
      : e.message ?? 'Failed to load salary slips');
    }
  }

  Future<List<SalarySlip>> getSalarySlipsByPeriod(int periodId) async {
    try {
      final response = await _dio.get('$_baseUrl/salary/slips/period/$periodId');
      final data = _unwrap(response.data);
      return (data as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((e) => SalarySlip.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data is Map
      ? e.response?.data['message']
      : e.message ?? 'Failed to load salary slips');
    }
  }

  Future<SalarySlip> getSalarySlip(int id) async {
    try {
      final response = await _dio.get('$_baseUrl/salary/slips/$id');
      final data = _unwrap(response.data);
      return SalarySlip.fromJson(data);
    } on DioException catch (e) {
      throw Exception(e.response?.data is Map
      ? e.response?.data['message']
      : e.message ?? 'Failed to load salary slip');
    }
  }

  Future<SalarySlip> generateSalarySlip(int employeeId, int periodId) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/salary/slips',
        data: {
          'employee_id': employeeId,
          'period_id': periodId,
        },
      );
      final data = _unwrap(response.data);
      return SalarySlip.fromJson(data);
    } on DioException catch (e) {
      throw Exception(e.response?.data is Map
      ? e.response?.data['message']
      : e.message ?? 'Failed to generate salary slip');
    }
  }

  Future<Map<String, dynamic>> bulkGenerateSlips(int periodId) async {
    try {
      final response = await _dio.post('$_baseUrl/salary/slips/bulk/$periodId');
      return _unwrap(response.data) as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data is Map
      ? e.response?.data['message']
      : e.message ?? 'Failed to bulk generate slips');
    }
  }

  Future<SalarySlip> updateSalarySlip(int id, Map<String, dynamic> payload) async {
    try {
      final response = await _dio.patch('$_baseUrl/salary/slips/$id', data: payload);
      final data = _unwrap(response.data);
      return SalarySlip.fromJson(data);
    } on DioException catch (e) {
      throw Exception(e.response?.data is Map
      ? e.response?.data['message']
      : e.message ?? 'Failed to update salary slip');
    }
  }

  Future<SalarySlip> processPayment(int id, {
    required DateTime paymentDate,
    required String paymentMode,
    String? transactionId,
  }) async {
    try {
      final response = await _dio.patch(
        '$_baseUrl/salary/slips/$id/payment',
        data: {
          'payment_date': DateFormat('yyyy-MM-dd').format(paymentDate),
          'payment_mode': paymentMode,
          if (transactionId != null) 'transaction_id': transactionId,
        },
      );
      return SalarySlip.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(e.response?.data is Map
      ? e.response?.data['message']
      : e.message ?? 'Failed to process payment');
    }
  }

  Future<void> deleteSalarySlip(int id) async {
    try {
      await _dio.delete('$_baseUrl/salary/slips/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data is Map
      ? e.response?.data['message']
      : e.message ?? 'Failed to delete salary slip');
    }
  }

  Future<List<SalaryAdvance>> getAdvances({int? employeeId}) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/salary/advances',
        queryParameters: employeeId != null ? {'employee_id': employeeId} : null,
      );
      final data = _unwrap(response.data);
      return (data as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((e) => SalaryAdvance.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data is Map
      ? e.response?.data['message']
      : e.message ?? 'Failed to load advances');
    }
  }

  Future<SalaryAdvance> createAdvance({
    required int employeeId,
    required double amount,
    required DateTime requestDate,
    String? reason,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/salary/advances',
        data: {
          'employee_id': employeeId,
          'amount': amount,
          'request_date': DateFormat('yyyy-MM-dd').format(requestDate),
          if (reason != null) 'reason': reason,
        },
      );
      return SalaryAdvance.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(e.response?.data is Map
      ? e.response?.data['message']
      : e.message ?? 'Failed to create advance');
    }
  }

  Future<void> approveAdvance(int id) async {
    try {
      await _dio.patch('$_baseUrl/salary/advances/$id/approve');
    } on DioException catch (e) {
      throw Exception(e.response?.data is Map
      ? e.response?.data['message']
      : e.message ?? 'Failed to approve advance');
    }
  }

  Future<void> rejectAdvance(int id) async {
    try {
      await _dio.patch('$_baseUrl/salary/advances/$id/reject');
    } on DioException catch (e) {
      throw Exception(e.response?.data is Map
      ? e.response?.data['message']
      : e.message ?? 'Failed to reject advance');
    }
  }

  Future<List<SalaryDeduction>> getDeductions() async {
    try {
      final response = await _dio.get('$_baseUrl/salary/deductions');
      final data = _unwrap(response.data);
      return (data as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((e) => SalaryDeduction.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data is Map
      ? e.response?.data['message']
      : e.message ?? 'Failed to load deductions');
    }
  }

  Future<SalarySummary> getSalarySummary(int periodId) async {
    try {
      final response = await _dio.get('$_baseUrl/salary/slips/summary/$periodId');
      final data = _unwrap(response.data);
      return SalarySummary.fromJson(data);
    } on DioException catch (e) {
      throw Exception(e.response?.data is Map
      ? e.response?.data['message']
      : e.message ?? 'Failed to load salary summary');
    }
  }

  Future<List<Department>> getDepartments() async {
    try {
      final response = await _dio.get('$_baseUrl/employees/departments');
      final data = _unwrap(response.data);
      return (data as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((e) => Department.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data is Map
      ? e.response?.data['message']
      : e.message ?? 'Failed to load departments');
    }
  }

  Future<SalaryDeduction> createDeduction({
    required String name,
    required String type,
    String? description,
    required String calculationType,
    required double value,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/salary/deductions',
        data: {
          'name': name,
          'type': type,
          if (description != null) 'description': description,
          'calculation_type': calculationType,
          'value': value,
        },
      );
      final data = _unwrap(response.data);
      return SalaryDeduction.fromJson(data);
    } on DioException catch (e) {
      throw Exception(e.response?.data is Map
      ? e.response?.data['message']
      : e.message ?? 'Failed to create deduction');
    }
  }

  Future<SalaryDeduction> updateDeduction(
    int id, {
    required String name,
    required String type,
    String? description,
    required String calculationType,
    required double value,
    bool? isActive,
  }) async {
    try {
      final response = await _dio.patch(
        '$_baseUrl/salary/deductions/$id',
        data: {
          'name': name,
          'type': type,
          if (description != null) 'description': description,
          'calculation_type': calculationType,
          'value': value,
          if (isActive != null) 'is_active': isActive,
        },
      );
      final data = _unwrap(response.data);
      return SalaryDeduction.fromJson(data);
    } on DioException catch (e) {
      throw Exception(e.response?.data is Map
      ? e.response?.data['message']
      : e.message ?? 'Failed to update deduction');
    }
  }

  Future<void> deleteDeduction(int id) async {
    try {
      await _dio.delete('$_baseUrl/salary/deductions/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data is Map
      ? e.response?.data['message']
      : e.message ?? 'Failed to delete deduction');
    }
  }

  // ── Earnings ────────────────────────────────────────────────

  Future<List<SalaryEarning>> getEarnings({bool activeOnly = false}) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/salary/earnings',
        queryParameters: activeOnly ? {'active': 'true'} : null,
      );
      final data = _unwrap(response.data);
      return (data as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((e) => SalaryEarning.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data is Map
      ? e.response?.data['message']
      : e.message ?? 'Failed to load earnings');
    }
  }

  Future<SalaryEarning> createEarning({
    required String name,
    required String type,
    String? description,
    required String calculationType,
    required double value,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/salary/earnings',
        data: {
          'name': name,
          'type': type,
          if (description != null) 'description': description,
          'calculation_type': calculationType,
          'value': value,
        },
      );
      final data = _unwrap(response.data);
      return SalaryEarning.fromJson(data);
    } on DioException catch (e) {
      throw Exception(e.response?.data is Map
      ? e.response?.data['message']
      : e.message ?? 'Failed to create earning');
    }
  }

  Future<SalaryEarning> updateEarning(
    int id, {
    required String name,
    required String type,
    String? description,
    required String calculationType,
    required double value,
    bool? isActive,
  }) async {
    try {
      final response = await _dio.patch(
        '$_baseUrl/salary/earnings/$id',
        data: {
          'name': name,
          'type': type,
          if (description != null) 'description': description,
          'calculation_type': calculationType,
          'value': value,
          if (isActive != null) 'is_active': isActive,
        },
      );
      final data = _unwrap(response.data);
      return SalaryEarning.fromJson(data);
    } on DioException catch (e) {
      throw Exception(e.response?.data is Map
      ? e.response?.data['message']
      : e.message ?? 'Failed to update earning');
    }
  }

  Future<void> deleteEarning(int id) async {
    try {
      await _dio.delete('$_baseUrl/salary/earnings/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data is Map
      ? e.response?.data['message']
      : e.message ?? 'Failed to delete earning');
    }
  }
}
