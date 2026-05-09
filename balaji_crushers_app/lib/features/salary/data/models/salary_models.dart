import 'package:balaji_crushers_app/core/utils/ist_date_utils.dart';

double _toDouble(dynamic val) {
  if (val == null) return 0;
  if (val is num) return val.toDouble();
  return double.tryParse(val.toString()) ?? 0;
}

int _toInt(dynamic val) {
  if (val == null) return 0;
  if (val is int) return val;
  return int.tryParse(val.toString()) ?? 0;
}

bool _toBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is String) {
    final lower = value.toLowerCase();
    return lower == 'true' || lower == 't' || lower == '1' || lower == 'yes';
  }
  if (value is int) return value != 0;
  return false;
}

class SalaryPeriod {
  final int? id;
  final int year;
  final int month;
  final DateTime startDate;
  final DateTime endDate;
  final bool isLocked;
  final DateTime? createdAt;

  SalaryPeriod({
    this.id,
    required this.year,
    required this.month,
    required this.startDate,
    required this.endDate,
    this.isLocked = false,
    this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SalaryPeriod &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          month == other.month;

  @override
  int get hashCode => year.hashCode ^ month.hashCode;

  factory SalaryPeriod.fromJson(Map<String, dynamic> json) {
    return SalaryPeriod(
      id: _toInt(json['id']),
      year: _toInt(json['year']),
      month: _toInt(json['month']),
      startDate: appParseIstDate(json['start_date']) ?? appTodayIstDate(),
      endDate: appParseIstDate(json['end_date']) ?? appTodayIstDate(),
      isLocked: _toBool(json['is_locked']),
      createdAt: json['created_at'] != null
          ? appParseIstDateTime(json['created_at'])
          : null,
    );
  }

  String get monthName {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[month - 1]} $year';
  }
}

class SalarySlip {
  final int? id;
  final int employeeId;
  final int periodId;
  final double basicSalary;
  final double hra;
  final double allowances;
  final double overtimeAmount;
  final double bonus;
  final double totalEarnings;
  final double pfDeduction;
  final double tdsDeduction;
  final double otherDeductions;
  final double totalDeductions;
  final double netSalary;
  final int? presentDays;
  final int? absentDays;
  final int? leaveDays;
  final int? halfDays;
  final int? sundays;       // total Sundays in month (all auto-paid)
  final double? extraDays;  // Sundays with attendance marked (extra worked)
  final double? workedDays;
  final int? totalDays;
  final String status;
  final DateTime? paymentDate;
  final String? paymentMode;
  final String? transactionId;
  final String? notes;
  final String? employeeCode;
  final String? firstName;
  final String? lastName;
  final String? departmentName;
  final int? departmentId;
  final String? bankAccount;
  final String? bankName;
  final String? ifscCode;
  final String? createdByName;

  SalarySlip({
    this.id,
    required this.employeeId,
    required this.periodId,
    this.basicSalary = 0,
    this.hra = 0,
    this.allowances = 0,
    this.overtimeAmount = 0,
    this.bonus = 0,
    this.totalEarnings = 0,
    this.pfDeduction = 0,
    this.tdsDeduction = 0,
    this.otherDeductions = 0,
    this.totalDeductions = 0,
    this.netSalary = 0,
    this.presentDays,
    this.absentDays,
    this.leaveDays,
    this.halfDays,
    this.sundays,
    this.extraDays,
    this.workedDays,
    this.totalDays,
    this.status = 'draft',
    this.paymentDate,
    this.paymentMode,
    this.transactionId,
    this.notes,
    this.employeeCode,
    this.firstName,
    this.lastName,
    this.departmentName,
    this.departmentId,
    this.bankAccount,
    this.bankName,
    this.ifscCode,
    this.createdByName,
  });

  String get employeeName => '${firstName ?? ''} ${lastName ?? ''}'.trim();

  factory SalarySlip.fromJson(Map<String, dynamic> json) {
    return SalarySlip(
      id: _toInt(json['id']),
      employeeId: _toInt(json['employee_id']),
      periodId: _toInt(json['period_id']),

      basicSalary: _toDouble(json['basic_salary']),
      hra: _toDouble(json['hra']),
      allowances: _toDouble(json['allowances']),
      overtimeAmount: _toDouble(json['overtime_amount']),
      bonus: _toDouble(json['bonus']),
      totalEarnings: _toDouble(json['total_earnings']),

      pfDeduction: _toDouble(json['pf_deduction']),
      tdsDeduction: _toDouble(json['tds_deduction']),
      otherDeductions: _toDouble(json['other_deductions']),
      totalDeductions: _toDouble(json['total_deductions']),
      netSalary: _toDouble(json['net_salary']),

      presentDays: _toInt(json['present_days']),
      absentDays: _toInt(json['absent_days']),
      leaveDays: _toInt(json['leave_days']),
      halfDays: _toInt(json['half_days']),
      sundays: _toInt(json['sundays']),
      extraDays: _toDouble(json['extra_days']),
      workedDays: _toDouble(json['worked_days']),
      totalDays: _toInt(json['total_days']),

      status: json['status']?.toString() ?? 'draft',

      paymentDate: json['payment_date'] != null
          ? appParseIstDate(json['payment_date'])
          : null,

      paymentMode: json['payment_mode']?.toString(),
      transactionId: json['transaction_id']?.toString(),
      notes: json['notes']?.toString(),

      employeeCode: json['employee_code']?.toString(),
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),

      departmentName: json['department_name']?.toString(),
      departmentId: _toInt(json['department_id']),

      bankAccount: json['bank_account']?.toString(),
      bankName: json['bank_name']?.toString(),
      ifscCode: json['ifsc_code']?.toString(),

      createdByName: json['created_by_name']?.toString(),
    );
  }
}

class SalaryAdvance {
  final int? id;
  final int employeeId;
  final double amount;
  final DateTime requestDate;
  final String? reason;
  final String status;
  final int? approvedBy;
  final DateTime? approvedAt;
  final DateTime? repaymentStartDate;
  final double repaymentAmount;
  final double totalRepaid;
  final double remainingAmount;
  final String? notes;
  final String? employeeCode;
  final String? firstName;
  final String? lastName;

  SalaryAdvance({
    this.id,
    required this.employeeId,
    required this.amount,
    required this.requestDate,
    this.reason,
    this.status = 'pending',
    this.approvedBy,
    this.approvedAt,
    this.repaymentStartDate,
    this.repaymentAmount = 0,
    this.totalRepaid = 0,
    this.remainingAmount = 0,
    this.notes,
    this.employeeCode,
    this.firstName,
    this.lastName,
  });

  String get employeeName => '${firstName ?? ''} ${lastName ?? ''}'.trim();

  factory SalaryAdvance.fromJson(Map<String, dynamic> json) {
    return SalaryAdvance(
      id: _toInt(json['id']),
      employeeId: _toInt(json['employee_id']),
      amount: _toDouble(json['amount']),
      requestDate: appParseIstDate(json['request_date']) ?? appTodayIstDate(),
      reason: json['reason']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      approvedBy: _toInt(json['approved_by']),
      approvedAt: json['approved_at'] != null
          ? appParseIstDateTime(json['approved_at'])
          : null,

      repaymentStartDate: json['repayment_start_date'] != null
          ? appParseIstDate(json['repayment_start_date'])
          : null,

      repaymentAmount: _toDouble(json['repayment_amount']),
      totalRepaid: _toDouble(json['total_repaid']),
      remainingAmount: _toDouble(json['remaining_amount']),
      notes: json['notes']?.toString(),
      employeeCode: json['employee_code']?.toString(),
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
    );
  }
}

class SalaryDeduction {
  final int? id;
  final String name;
  final String type;
  final String calculationType;
  final double value;
  final bool? isActive;
  final String? description;

  SalaryDeduction({
    this.id,
    required this.name,
    required this.type,
    this.calculationType = 'percentage',
    this.value = 0,
    this.isActive = true,
    this.description,
  });

  factory SalaryDeduction.fromJson(Map<String, dynamic> json) {
    return SalaryDeduction(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'other',
      calculationType: json['calculation_type']?.toString() ?? 'percentage',
      value: _toDouble(json['value']),
      isActive: _toBool(json['is_active']),
      description: json['description']?.toString(),
    );
  }
}

class SalaryEarning {
  final int? id;
  final String name;
  final String type; // hra, allowance, bonus, other
  final String calculationType; // percentage, fixed
  final double value;
  final bool? isActive;
  final String? description;

  SalaryEarning({
    this.id,
    required this.name,
    required this.type,
    this.calculationType = 'percentage',
    this.value = 0,
    this.isActive = true,
    this.description,
  });

  factory SalaryEarning.fromJson(Map<String, dynamic> json) {
    return SalaryEarning(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'other',
      calculationType: json['calculation_type']?.toString() ?? 'percentage',
      value: _toDouble(json['value']),
      isActive: _toBool(json['is_active']),
      description: json['description']?.toString(),
    );
  }
}

class SalarySummary {
  final int totalEmployees;
  final double totalEarnings;
  final double totalDeductions;
  final double totalNetSalary;
  final int paidCount;
  final int pendingCount;

  SalarySummary({
    this.totalEmployees = 0,
    this.totalEarnings = 0,
    this.totalDeductions = 0,
    this.totalNetSalary = 0,
    this.paidCount = 0,
    this.pendingCount = 0,
  });

  factory SalarySummary.fromJson(Map<String, dynamic> json) {
    return SalarySummary(
      totalEmployees: _toInt(json['total_employees']),
      totalEarnings: _toDouble(json['total_earnings']),
      totalDeductions: _toDouble(json['total_deductions']),
      totalNetSalary: _toDouble(json['total_net_salary']),
      paidCount: _toInt(json['paid_count']),
      pendingCount: _toInt(json['pending_count']),
    );
  }
}

class EmployeeSalary {
  final int id;
  final String employeeCode;
  final String firstName;
  final String? lastName;
  final double salary;
  final int? departmentId;
  final String? departmentName;
  final String employeeType;

  EmployeeSalary({
    required this.id,
    required this.employeeCode,
    required this.firstName,
    this.lastName,
    this.salary = 0,
    this.departmentId,
    this.departmentName,
    this.employeeType = 'permanent',
  });

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();

  factory EmployeeSalary.fromJson(Map<String, dynamic> json) {
    return EmployeeSalary(
      id: _toInt(json['id']),
      employeeCode: json['employee_code']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString(),
      salary: _toDouble(json['salary']),
      departmentId: _toInt(json['department_id']),
      departmentName: json['department_name']?.toString(),
      employeeType: json['employee_type']?.toString() ?? 'permanent',
    );
  }
}

class Department {
  final int id;
  final String name;
  final String? description;

  const Department({
    required this.id,
    required this.name,
    this.description,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }
}
