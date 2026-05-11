import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:balaji_crushers_app/features/salary/data/models/salary_models.dart';
import 'package:balaji_crushers_app/features/salary/data/repositories/salary_repository.dart';
import 'package:balaji_crushers_app/features/attendance/data/attendance_repository.dart';
import 'package:balaji_crushers_app/features/attendance/presentation/providers/attendance_provider.dart';

final salaryRepositoryProvider = Provider((ref) => SalaryRepository());

int _comparePeriodsNewestFirst(SalaryPeriod a, SalaryPeriod b) {
  final byYear = b.year.compareTo(a.year);
  if (byYear != 0) return byYear;
  return b.month.compareTo(a.month);
}

int _compareEmployeeSalaryByName(EmployeeSalary a, EmployeeSalary b) {
  final byName = a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
  if (byName != 0) return byName;
  return a.id.compareTo(b.id);
}

int _compareDepartmentsByName(Department a, Department b) {
  final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
  if (byName != 0) return byName;
  return a.id.compareTo(b.id);
}

int _compareSalarySlipsByEmployee(SalarySlip a, SalarySlip b) {
  final byName = a.employeeName.toLowerCase().compareTo(b.employeeName.toLowerCase());
  if (byName != 0) return byName;
  return (a.id ?? 0).compareTo(b.id ?? 0);
}

int _compareAdvancesNewestFirst(SalaryAdvance a, SalaryAdvance b) {
  final byDate = b.requestDate.compareTo(a.requestDate);
  if (byDate != 0) return byDate;
  return (b.id ?? 0).compareTo(a.id ?? 0);
}

int _compareDeductionsByName(SalaryDeduction a, SalaryDeduction b) {
  final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
  if (byName != 0) return byName;
  return (a.id ?? 0).compareTo(b.id ?? 0);
}

int _compareEarningsByName(SalaryEarning a, SalaryEarning b) {
  final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
  if (byName != 0) return byName;
  return (a.id ?? 0).compareTo(b.id ?? 0);
}

final periodsProvider = FutureProvider<List<SalaryPeriod>>((ref) async {
  final repo = ref.read(salaryRepositoryProvider);
  return (await repo.getPeriods())..sort(_comparePeriodsNewestFirst);
});

final periodByIdProvider = FutureProvider.family<SalaryPeriod?, int>((ref, id) async {
  final repo = ref.read(salaryRepositoryProvider);
  final periods = await repo.getPeriods();
  return periods.where((p) => p.id == id).isNotEmpty
    ? periods.firstWhere((p) => p.id == id)
    : null;
});

String _formatDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String _attendanceDateKey(String rawDate) {
  if (!rawDate.contains('T')) return rawDate;
  final hasTimeZone = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(rawDate);
  if (!hasTimeZone) return rawDate.split('T')[0];

  final parsed = DateTime.tryParse(rawDate);
  if (parsed == null) return rawDate.split('T')[0];

  final istDate = parsed.toUtc().add(const Duration(hours: 5, minutes: 30));
  return _formatDate(istDate);
}

/// Fetches all attendance records for a given employee in a given salary period.
/// Returns records sorted chronologically (day 1 → day N).
final employeeAttendanceByPeriodProvider = FutureProvider.autoDispose
    .family<List<AttendanceRecord>, ({int employeeId, int periodId})>(
  (ref, params) async {
    // Use ref.read — watching inside an async body is unreliable
    final period = await ref.read(
      periodByIdProvider(params.periodId).future,
    );
    if (period == null) return [];

    // Salary periods are calendar months. Build explicit IST date keys from
    // year/month so Postgres DATE values serialized as UTC cannot shift a day.
    final monthStart = DateTime(period.year, period.month, 1);
    final monthEnd = DateTime(period.year, period.month + 1, 0);
    final startDate = _formatDate(monthStart);
    final endDate = _formatDate(monthEnd);

    final raw = await AttendanceRepository().getAttendance(
      startDate: startDate,
      endDate: endDate,
      employeeId: params.employeeId,
    );

    final records = raw
        .whereType<Map<String, dynamic>>()
        .map(AttendanceRecord.fromJson)
        .toList()
      // Sort ascending so day 1 comes first
      ..sort((a, b) => _attendanceDateKey(a.date).compareTo(_attendanceDateKey(b.date)));

    return records;
  },
);

final employeesForSalaryProvider = FutureProvider<List<EmployeeSalary>>((ref) async {
  final repo = ref.read(salaryRepositoryProvider);
  return (await repo.getEmployees())..sort(_compareEmployeeSalaryByName);
});

final departmentsForSalaryProvider = FutureProvider<List<Department>>((ref) async {
  final repo = ref.read(salaryRepositoryProvider);
  return (await repo.getDepartments())..sort(_compareDepartmentsByName);
});
 
final salarySlipsByPeriodProvider = FutureProvider.family<List<SalarySlip>, int>((ref, periodId) async {
  final repo = ref.read(salaryRepositoryProvider);
  return (await repo.getSalarySlipsByPeriod(periodId))..sort(_compareSalarySlipsByEmployee);
});

final salarySlipProvider = FutureProvider.family<SalarySlip, int>((ref, id) async {
  final repo = ref.read(salaryRepositoryProvider);
  return repo.getSalarySlip(id);
});
 
final salarySummaryProvider = FutureProvider.family<SalarySummary, int>((ref, periodId) async {
  final repo = ref.read(salaryRepositoryProvider);
  final data = await repo.getSalarySummary(periodId);
  return data ?? SalarySummary();
});

final advancesProvider = FutureProvider.family<List<SalaryAdvance>, int?>((ref, employeeId) async {
  final repo = ref.read(salaryRepositoryProvider);
  return (await repo.getAdvances(employeeId: employeeId))..sort(_compareAdvancesNewestFirst);
});

final deductionsProvider = FutureProvider<List<SalaryDeduction>>((ref) async {
  final repo = ref.read(salaryRepositoryProvider);
  return (await repo.getDeductions())..sort(_compareDeductionsByName);
});

class SalaryNotifier extends StateNotifier<AsyncValue<List<SalarySlip>>> {
  int? _lastPeriodId;
  int? _lastEmployeeId;
  String? _lastStatus;
  int? _lastDepartmentId;

  final SalaryRepository _repo;
  final Ref _ref;

  SalaryNotifier(this._repo, this._ref) : super(const AsyncValue.loading());

  Future<void> loadSlips({
    int? periodId,
    int? employeeId,  
    String? status,
    int? departmentId,
  }) async {
    _lastPeriodId = periodId;
    _lastEmployeeId = employeeId;
    _lastStatus = status;
    _lastDepartmentId = departmentId;

    state = const AsyncValue.loading();

    try {
      final slips = await _repo.getSalarySlips(
        periodId: periodId,
        employeeId: employeeId,
        status: status,
        departmentId: departmentId,
      );

      slips.sort(_compareSalarySlipsByEmployee);
      state = AsyncValue.data(slips);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

// Currently not being used
Future<void> loadMore() async {
  if (state.isLoading || state.hasError) return;

  final slips = state.value ?? [];
  final currentPage = (slips.length ~/ 20) + 1;

  try {
    final newSlips = await _repo.getSalarySlips(
      periodId: _lastPeriodId,
      employeeId: _lastEmployeeId,
      status: _lastStatus,
      departmentId: _lastDepartmentId,
    );

    state = AsyncValue.data([...slips, ...newSlips]);
  } catch (e, st) {
    state = AsyncValue.error(e, st);
  }
}

  Future<SalarySlip> generateSlip(int employeeId, int periodId) async {
    final slip = await _repo.generateSalarySlip(employeeId, periodId);
    _ref.invalidate(salarySlipsByPeriodProvider(periodId));
    _ref.invalidate(salarySummaryProvider(periodId));
    await loadSlips(
      periodId: periodId,
      employeeId: _lastEmployeeId,
      status: _lastStatus,
      departmentId: _lastDepartmentId,
    );
    return slip;
  }

  Future<Map<String, dynamic>> bulkGenerate(int periodId) async {
    final result = await _repo.bulkGenerateSlips(periodId);
    _ref.invalidate(salarySlipsByPeriodProvider(periodId));
    _ref.invalidate(salarySummaryProvider(periodId));
    await loadSlips(
      periodId: periodId,
      employeeId: _lastEmployeeId,
      status: _lastStatus,
      departmentId: _lastDepartmentId,
    );  
    return result;
  }

  Future<void> updateSlip(int id, Map<String, dynamic> data) async {
    await _repo.updateSalarySlip(id, data);
    await loadSlips(
      periodId: _lastPeriodId,
      employeeId: _lastEmployeeId,
      status: _lastStatus,
      departmentId: _lastDepartmentId,
    );
  }

  Future<void> processPayment(int id, {
    required DateTime paymentDate,
    required String paymentMode,
    String? transactionId,
  }) async {
    await _repo.processPayment(id, paymentDate: paymentDate, paymentMode: paymentMode, transactionId: transactionId);
    await loadSlips(
      periodId: _lastPeriodId,
      employeeId: _lastEmployeeId,
      status: _lastStatus,
      departmentId: _lastDepartmentId,
    );  
  }

  Future<void> deleteSlip(int id) async {
    await _repo.deleteSalarySlip(id);
    // Reload slips after delete
    await loadSlips(
      periodId: _lastPeriodId,
      employeeId: _lastEmployeeId,
      status: _lastStatus,
      departmentId: _lastDepartmentId,
    );
  }
}

final salaryNotifierProvider = StateNotifierProvider<SalaryNotifier, AsyncValue<List<SalarySlip>>>((ref) {
  return SalaryNotifier(ref.read(salaryRepositoryProvider), ref);
});
 
class AdvanceNotifier extends StateNotifier<AsyncValue<List<SalaryAdvance>>> {
  int? _lastEmployeeId;

  final SalaryRepository _repo;
  final Ref _ref;

  AdvanceNotifier(this._repo, this._ref) : super(const AsyncValue.loading()) {
    loadAdvances();
  }

  Future<void> loadAdvances({int? employeeId}) async {
    _lastEmployeeId = employeeId;
    state = const AsyncValue.loading();
    try {
      final advances = await _repo.getAdvances(employeeId: employeeId);
      advances.sort(_compareAdvancesNewestFirst);
      state = AsyncValue.data(advances);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<SalaryAdvance> createAdvance({
    required int employeeId,
    required double amount,
    required DateTime requestDate,
    String? reason,
  }) async {
    final advance = await _repo.createAdvance(
      employeeId: employeeId,
      amount: amount,
      requestDate: requestDate,
      reason: reason,
    );
    await loadAdvances(employeeId: _lastEmployeeId);
    return advance;
  }

  Future<void> approveAdvance(int id) async {
    await _repo.approveAdvance(id);
    await loadAdvances(employeeId: _lastEmployeeId);
  }

  Future<void> rejectAdvance(int id) async {
    await _repo.rejectAdvance(id);
    await loadAdvances(employeeId: _lastEmployeeId);
  }
}

final advanceNotifierProvider = StateNotifierProvider<AdvanceNotifier, AsyncValue<List<SalaryAdvance>>>((ref) {
  return AdvanceNotifier(ref.read(salaryRepositoryProvider), ref);
});

class DeductionNotifier extends StateNotifier<AsyncValue<List<SalaryDeduction>>> {
  final SalaryRepository _repo;
  final Ref _ref;

  DeductionNotifier(this._repo, this._ref) : super(const AsyncValue.loading()) {
    loadDeductions();
  }

  Future<void> loadDeductions() async {
    state = const AsyncValue.loading();
    try {
      final deductions = await _repo.getDeductions();
      deductions.sort(_compareDeductionsByName);
      state = AsyncValue.data(deductions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<SalaryDeduction> createDeduction({
    required String name,
    required String type,
    String? description,
    required String calculationType,
    required double value,
  }) async {
    final deduction = await _repo.createDeduction(
      name: name,
      type: type,
      description: description,
      calculationType: calculationType,
      value: value,
    );
    await loadDeductions();
    return deduction;
  }

  Future<void> updateDeduction(
    int id, {
    required String name,
    required String type,
    String? description,
    required String calculationType,
    required double value,
    bool? isActive,
  }) async {
    await _repo.updateDeduction(
      id,
      name: name,
      type: type,
      description: description,
      calculationType: calculationType,
      value: value,
      isActive: isActive,
    );
    await loadDeductions();
  }

  Future<void> deleteDeduction(int id) async {
    await _repo.deleteDeduction(id);
    await loadDeductions();
  }
}

final deductionNotifierProvider = StateNotifierProvider<DeductionNotifier, AsyncValue<List<SalaryDeduction>>>((ref) {
  return DeductionNotifier(ref.read(salaryRepositoryProvider), ref);
});

// Convenience providers for detail dialog (active only)
final activeDeductionsProvider = FutureProvider<List<SalaryDeduction>>((ref) async {
  final repo = ref.read(salaryRepositoryProvider);
  final all = await repo.getDeductions();
  return all.where((d) => d.isActive == true).toList()
    ..sort(_compareDeductionsByName);
});

final activeEarningsProvider = FutureProvider<List<SalaryEarning>>((ref) async {
  final repo = ref.read(salaryRepositoryProvider);
  return (await repo.getEarnings(activeOnly: true))..sort(_compareEarningsByName);
});

class EarningNotifier extends StateNotifier<AsyncValue<List<SalaryEarning>>> {
  final SalaryRepository _repo;
  final Ref _ref;

  EarningNotifier(this._repo, this._ref) : super(const AsyncValue.loading()) {
    loadEarnings();
  }

  Future<void> loadEarnings() async {
    state = const AsyncValue.loading();
    try {
      final earnings = await _repo.getEarnings();
      earnings.sort(_compareEarningsByName);
      state = AsyncValue.data(earnings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<SalaryEarning> createEarning({
    required String name,
    required String type,
    String? description,
    required String calculationType,
    required double value,
  }) async {
    final earning = await _repo.createEarning(
      name: name, type: type, description: description,
      calculationType: calculationType, value: value,
    );
    await loadEarnings();
    return earning;
  }

  Future<void> updateEarning(
    int id, {
    required String name,
    required String type,
    String? description,
    required String calculationType,
    required double value,
    bool? isActive,
  }) async {
    await _repo.updateEarning(
      id,
      name: name, type: type, description: description,
      calculationType: calculationType, value: value, isActive: isActive,
    );
    await loadEarnings();
  }

  Future<void> deleteEarning(int id) async {
    await _repo.deleteEarning(id);
    await loadEarnings();
  }
}

final earningNotifierProvider = StateNotifierProvider<EarningNotifier, AsyncValue<List<SalaryEarning>>>((ref) {
  return EarningNotifier(ref.read(salaryRepositoryProvider), ref);
});
