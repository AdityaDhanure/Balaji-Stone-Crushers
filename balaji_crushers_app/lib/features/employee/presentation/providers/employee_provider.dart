import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_refresh_provider.dart';
import '../../data/employee_repository.dart';

final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  return EmployeeRepository();
});

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  return int.tryParse(v.toString()) ?? 0;
}

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

dynamic _unwrap(dynamic res) {
  if (res is Map<String, dynamic> && res.containsKey('data')) {
    return res['data'];
  }
  return res;
}

class EmployeeState {
  final bool isLoading;
  final List<Employee> employees;
  final List<Department> departments;
  final List<PendingLeave> pendingLeaves;
  final EmployeeStats? stats;
  final String? error;

  const EmployeeState({
    this.isLoading = false,
    this.employees = const [],
    this.departments = const [],
    this.pendingLeaves = const [],
    this.stats,
    this.error,
  });

  EmployeeState copyWith({
    bool? isLoading,
    List<Employee>? employees,
    List<Department>? departments,
    List<PendingLeave>? pendingLeaves,
    EmployeeStats? stats,
    String? error,
  }) {
    return EmployeeState(
      isLoading: isLoading ?? this.isLoading,
      employees: employees ?? this.employees,
      departments: departments ?? this.departments,
      pendingLeaves: pendingLeaves ?? this.pendingLeaves,
      stats: stats ?? this.stats,
      error: error,
    );
  }
}

class EmployeeStats {
  final int totalEmployees;
  final int activeCount;
  final int permanentCount;
  final int contractCount;
  final int dailyWagers;
  final double totalSalary;

  const EmployeeStats({
    this.totalEmployees = 0,
    this.activeCount = 0,
    this.permanentCount = 0,
    this.contractCount = 0,
    this.dailyWagers = 0,
    this.totalSalary = 0,
  });

  factory EmployeeStats.fromJson(Map<String, dynamic> json) {
    return EmployeeStats(
      totalEmployees: _toInt(json['total_employees']),
      activeCount: _toInt(json['active_count']),
      permanentCount: _toInt(json['permanent_count']),
      contractCount: _toInt(json['contract_count']),
      dailyWagers: _toInt(json['daily_wagers']),
      totalSalary: _toDouble(json['total_salary']),
    );
  }
}

class Employee {
  final int id;
  final String employeeCode;
  final String firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? dateOfBirth;
  final String dateOfJoining;
  final String? dateOfLeaving;
  final int? departmentId;
  final String? departmentName;
  final String? designation;
  final String employeeType;
  final double salary;
  final int? paidLeaveBalance;
  final int? leavesTaken;
  final String? aadhaarNumber;
  final String? panNumber;
  final String? bankAccount;
  final String? bankName;
  final String? ifscCode;
  final String? upiId;
  final String? address;
  final String? city;
  final String? state;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelation;
  final bool isActive;
  final String? notes;

  const Employee({
    required this.id,
    required this.employeeCode,
    required this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.dateOfBirth,
    required this.dateOfJoining,
    this.dateOfLeaving,
    this.departmentId,
    this.departmentName,
    this.designation,
    this.employeeType = 'permanent',
    this.salary = 0,
    this.paidLeaveBalance,
    this.leavesTaken,
    this.aadhaarNumber,
    this.panNumber,
    this.bankAccount,
    this.bankName,
    this.ifscCode,
    this.upiId,
    this.address,
    this.city,
    this.state,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelation,
    this.isActive = true,
    this.notes,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: _toInt(json['id']),
      employeeCode: json['employee_code']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      dateOfBirth: json['date_of_birth']?.toString(),
      dateOfJoining: json['date_of_joining']?.toString() ?? '',
      dateOfLeaving: json['date_of_leaving']?.toString(),
      departmentId: json['department_id'] != null ? _toInt(json['department_id']) : null,
      departmentName: json['department_name']?.toString(),
      designation: json['designation']?.toString(),
      employeeType: json['employee_type']?.toString() ?? 'permanent',
      salary: _toDouble(json['salary']),
      paidLeaveBalance: _toInt(json['paid_leave_balance']),
      leavesTaken: _toInt(json['leaves_taken']),
      aadhaarNumber: json['aadhaar_number']?.toString(),
      panNumber: json['pan_number']?.toString(),
      bankAccount: json['bank_account']?.toString(),
      bankName: json['bank_name']?.toString(),
      ifscCode: json['ifsc_code']?.toString(),
      upiId: json['upi_id']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      emergencyContactName: json['emergency_contact_name']?.toString(),
      emergencyContactPhone: json['emergency_contact_phone']?.toString(),
      emergencyContactRelation: json['emergency_contact_relation']?.toString(),
      isActive: json['is_active'] == true || json['is_active'] == 1 || json['is_active'] == 'true' || json['is_active'] == 't',
      notes: json['notes']?.toString(),
    );
  }

  String get fullName => lastName != null ? '$firstName $lastName' : firstName;

  String get typeDisplay {
    switch (employeeType) {
      case 'contract':
        return 'Contract';
      case 'daily':
        return 'Daily Wager';
      default:
        return 'Permanent';
    }
  }

  int get remainingPaidLeaves {
    final balance = paidLeaveBalance ?? 15;
    final taken = leavesTaken ?? 0;
    return balance - taken;
  }
}

class Department {
  final int id;
  final String name;
  final String? description;
  final int employeeCount;

  const Department({
    required this.id,
    required this.name,
    this.description,
    this.employeeCount = 0,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      employeeCount: _toInt(json['employee_count']),
    );
  }
}

class PendingLeave {
  final int id;
  final int employeeId;
  final String employeeName;
  final String? departmentName;
  final String leaveType;
  final String startDate;
  final String endDate;
  final int totalDays;
  final String? reason;
  final String status;

  const PendingLeave({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    this.departmentName,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    this.totalDays = 1,
    this.reason,
    this.status = 'pending',
  });

  factory PendingLeave.fromJson(Map<String, dynamic> json) {
    final firstName = json['first_name']?.toString() ?? '';
    final lastName = json['last_name']?.toString();
    final employeeName = lastName != null ? '$firstName $lastName' : firstName;
    
    return PendingLeave(
      id: _toInt(json['id']),
      employeeId: _toInt(json['employee_id']),
      employeeName: employeeName.isNotEmpty
          ? employeeName
          : json['employee_name']?.toString() ?? 'Unknown',
      departmentName: json['department_name']?.toString(),
      leaveType: json['leave_type']?.toString() ?? '',
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      totalDays: _toInt(json['total_days']),
      reason: json['reason']?.toString(),
      status: json['status']?.toString() ?? 'pending',
    );
  }

  String get leaveTypeDisplay {
    switch (leaveType) {
      case 'sick':
        return 'Sick Leave';
      case 'casual':
        return 'Casual Leave';
      case 'earned':
        return 'Earned Leave';
      case 'unpaid':
        return 'Unpaid Leave';
      case 'maternity':
        return 'Maternity Leave';
      case 'paternity':
        return 'Paternity Leave';
      default:
        return leaveType;
    }
  }
}

class EmployeeNotifier extends StateNotifier<EmployeeState> {
  final EmployeeRepository _repository;

  EmployeeNotifier(this._repository) : super(const EmployeeState());

  Future<void> loadEmployees({bool isActive = true}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repository.getEmployees(isActive: isActive);
      final employees = (data as List)
          .whereType<Map<String, dynamic>>()
          .map(Employee.fromJson)
          .toList();
      state = state.copyWith(employees: employees);
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> loadAllEmployees() async {
    try {
      final data = await _repository.getAllEmployees();
      final employees = (data as List)
          .whereType<Map<String, dynamic>>()
          .map(Employee.fromJson)
          .toList();

      state = state.copyWith(employees: employees);
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> loadDepartments() async {
    try {
      final data = await _repository.getDepartments();
      final departments = (data as List)
          .whereType<Map<String, dynamic>>()
          .map(Department.fromJson)
          .toList();
      state = state.copyWith(departments: departments);
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> loadPendingLeaves() async {
    try {
      final data = await _repository.getPendingLeaves();
      final leaves = (data as List)
          .whereType<Map<String, dynamic>>()
          .map(PendingLeave.fromJson)
          .toList();
      state = state.copyWith(pendingLeaves: leaves);
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> loadStats() async {
    try {
      final data = await _repository.getEmployeeStats();
      state = state.copyWith(stats: EmployeeStats.fromJson(data));
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<bool> createEmployee(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.createEmployee(data);
      await loadAllData();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> updateEmployee(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.updateEmployee(id, data);
      await loadAllData();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> deleteEmployee(int id) async {
    try {
      await _repository.deleteEmployee(id);
      await loadAllData();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<String> getNextEmployeeCode() async {
    try {
      return await _repository.getNextEmployeeCode();
    } catch (e) {
      return 'EMP-001';
    }
  }

  Future<bool> approveLeave(int id) async {
    try {
      await _repository.approveLeave(id);
      await loadPendingLeaves();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> rejectLeave(int id) async {
    try {
      await _repository.rejectLeave(id);
      await loadPendingLeaves();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<void> loadAllData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final results = await Future.wait([
        _repository.getAllEmployees(),
        _repository.getDepartments(),
        _repository.getPendingLeaves(),
        _repository.getEmployeeStats(),
      ]);

      final employees = (results[0] as List)
          .whereType<Map<String, dynamic>>()
          .map(Employee.fromJson)
          .toList();

      final departments = (results[1] as List)
          .whereType<Map<String, dynamic>>()
          .map(Department.fromJson)
          .toList();

      final leaves = (results[2] as List)
          .whereType<Map<String, dynamic>>()
          .map(PendingLeave.fromJson)
          .toList();

      final stats = EmployeeStats.fromJson(results[3]);

      state = state.copyWith(
        isLoading: false,
        employees: employees,
        departments: departments,
        pendingLeaves: leaves,
        stats: stats,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}

final employeeProvider = StateNotifierProvider<EmployeeNotifier, EmployeeState>((ref) {
  final notifier = EmployeeNotifier(ref.read(employeeRepositoryProvider));
  ref.listen<int>(appRefreshProvider, (_, __) {
    notifier.loadAllData();
  });
  return notifier;
});
