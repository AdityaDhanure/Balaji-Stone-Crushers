import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_refresh_provider.dart';
import '../../data/attendance_repository.dart';
import '../../utils/attendance_date_utils.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository();
});

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  return int.tryParse(v.toString()) ?? 0;
}

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

class AttendanceState {
  final bool isLoading;
  final List<AttendanceRecord> records;
  final DailySummary? summary;
  final List<ShiftType> shifts;
  final String? error;

  const AttendanceState({
    this.isLoading = false,
    this.records = const [],
    this.summary,
    this.shifts = const [],
    this.error,
  });

  AttendanceState copyWith({
    bool? isLoading,
    List<AttendanceRecord>? records,
    DailySummary? summary,
    List<ShiftType>? shifts,
    String? error,
  }) {
    return AttendanceState(
      isLoading: isLoading ?? this.isLoading,
      records: records ?? this.records,
      summary: summary ?? this.summary,
      shifts: shifts ?? this.shifts,
      error: error,
    );
  }
}

class DailySummary {
  final int presentCount;
  final int absentCount;
  final int halfDayCount;
  final int onLeaveCount;
  final int holidayCount;
  final double totalOvertime;

  const DailySummary({
    this.presentCount = 0,
    this.absentCount = 0,
    this.halfDayCount = 0,
    this.onLeaveCount = 0,
    this.holidayCount = 0,
    this.totalOvertime = 0,
  });

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      presentCount: _toInt(json['present_count']),
      absentCount: _toInt(json['absent_count']),
      halfDayCount: _toInt(json['half_day_count']),
      onLeaveCount: _toInt(json['on_leave_count']),
      holidayCount: _toInt(json['holiday_count']),
      totalOvertime: _toDouble(json['total_overtime']),
    );
  }

  int get totalEmployees => presentCount + absentCount + halfDayCount + onLeaveCount + holidayCount;
}

class AttendanceRecord {
  final int id;
  final int employeeId;
  final String employeeName;
  final String employeeCode;
  final String? departmentName;
  final String date;
  final String? checkIn;
  final String? checkOut;
  final String status;
  final double overtimeHours;
  final double lateHours;
  final String? notes;

  const AttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
    this.departmentName,
    required this.date,
    this.checkIn,
    this.checkOut,
    required this.status,
    this.overtimeHours = 0,
    this.lateHours = 0,
    this.notes,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    final firstName = json['first_name']?.toString() ?? '';
    final lastName = json['last_name']?.toString();
    final fullName = lastName != null ? '$firstName $lastName' : firstName;
    
    return AttendanceRecord(
      id: _toInt(json['id']),
      employeeId: _toInt(json['employee_id']),
      employeeName: fullName.isNotEmpty ? fullName : 'Unknown',
      employeeCode: json['employee_code']?.toString() ?? '',
      departmentName: json['department_name']?.toString(),
      date: attendanceDateString(json['date']),
      checkIn: json['check_in']?.toString(),
      checkOut: json['check_out']?.toString(),
      status: json['status']?.toString() ?? 'present',
      overtimeHours: _toDouble(json['overtime_hours']),
      lateHours: _toDouble(json['late_hours']),
      notes: json['notes']?.toString(),
    );
  }

  String get statusDisplay {
    switch (status) {
      case 'present':
        return 'Present';
      case 'absent':
        return 'Absent';
      case 'half_day':
        return 'Half Day';
      case 'leave':
        return 'On Leave';
      case 'holiday':
        return 'Holiday';
      default:
        return status;
    }
  }

  static String to12Hour(String? time24) {
    if (time24 == null || time24.isEmpty) return '';
    try {
      final parts = time24.split(':');
      if (parts.length < 2) return time24;
      int hour = int.parse(parts[0]);
      final minute = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      return '$hour:$minute $period';
    } catch (e) {
      return time24;
    }
  }
}

class ShiftType {
  final int id;
  final String name;
  final String startTime;
  final String endTime;
  final int graceMinutes;

  const ShiftType({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    this.graceMinutes = 15,
  });

  factory ShiftType.fromJson(Map<String, dynamic> json) {
    return ShiftType(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      graceMinutes: _toInt(json['grace_minutes']),
    );
  }

  String get timeDisplay => '${ShiftType.to12Hour(startTime)} - ${ShiftType.to12Hour(endTime)}';

  static String to12Hour(String? time24) {
    if (time24 == null || time24.isEmpty) return '';
    try {
      final parts = time24.split(':');
      if (parts.length < 2) return time24;
      int hour = int.parse(parts[0]);
      final minute = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      return '$hour:$minute $period';
    } catch (e) {
      return time24;
    }
  }

  static String to24Hour(String time12) {
    try {
      final parts = time12.trim().toUpperCase().split(' ');
      if (parts.length < 2) return time12;
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      final minute = timeParts.length > 1 ? timeParts[1] : '00';
      final period = parts[1];
      if (period == 'PM' && hour != 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;
      return '${hour.toString().padLeft(2, '0')}:$minute';
    } catch (e) {
      return time12;
    }
  }
}

class AttendanceNotifier extends StateNotifier<AttendanceState> {
  String _currentDate = '';
  final AttendanceRepository _repository;

  AttendanceNotifier(this._repository) : super(const AttendanceState());

  Future<void> loadAttendance({String? date}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final targetDate = date ?? _currentDate;
      final data = await _repository.getAttendance(date: targetDate);
      final records = (data as List)
        .whereType<Map<String, dynamic>>()
        .map(AttendanceRecord.fromJson)
        .toList();
      state = state.copyWith(isLoading: false, records: records);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> loadSummary(String date) async {
    try {
      final data = await _repository.getDailySummary(date);
      state = state.copyWith(summary: DailySummary.fromJson(data));
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> loadShifts() async {
    try {
      final data = await _repository.getShifts();
      final shifts = (data as List)
        .whereType<Map<String, dynamic>>()
        .map(ShiftType.fromJson)
        .toList();
      state = state.copyWith(shifts: shifts);
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<bool> markAttendance(Map<String, dynamic> data) async {
    // Use the date from the record itself, not _currentDate which may lag.
    final date = data['date'] as String? ?? _currentDate;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.markAttendance(data);
      await loadAllData(date.isNotEmpty ? date : _currentDate);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> bulkMarkAttendance(List<Map<String, dynamic>> records) async {
    if (records.isEmpty) return false;
    // Use the date from the first record (all records share the same date).
    final date = records.first['date'] as String? ?? _currentDate;

    state = state.copyWith(isLoading: true, error: null);
    try {
      // Repository throws on HTTP error — if we reach the next line it succeeded.
      await _repository.bulkMarkAttendance(records);
      await loadAllData(date.isNotEmpty ? date : _currentDate);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
// Currently not being used anywhere
  Future<void> _forceReload(String? date) async {
    final targetDate = date ?? attendanceDateParam(attendanceTodayIstDate());
    
    state = state.copyWith(isLoading: true);
    try {
      final data = await _repository.getAttendance(date: targetDate);
      final records = (data as List)
        .whereType<Map<String, dynamic>>()
        .map(AttendanceRecord.fromJson)
        .toList();
      
      final summaryData = await _repository.getDailySummary(targetDate);
      final summary = DailySummary.fromJson(summaryData);
      
      final shiftsData = await _repository.getShifts();
      final shifts = (shiftsData as List)
        .whereType<Map<String, dynamic>>()
        .map(ShiftType.fromJson)
        .toList();
      
      state = state.copyWith(
        isLoading: false,
        records: records,
        summary: summary,
        shifts: shifts,
      );
    } catch (e) {
      debugPrint('Error reloading attendance: $e');
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<bool> updateAttendance(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.updateAttendance(id, data);
      await loadAllData(_currentDate);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> deleteAttendance(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deleteAttendance(id);
      await loadAllData(_currentDate);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  /// Deletes ALL attendance records for the currently loaded date.
  Future<bool> deleteAllForDate() async {
    if (_currentDate.isEmpty) return false;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deleteAllByDate(_currentDate);
      await loadAllData(_currentDate);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<void> loadAllData(String date) async {
    _currentDate = date;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final results = await Future.wait([
        _repository.getAttendance(date: date),
        _repository.getDailySummary(date),
        _repository.getShifts(),
      ]);

      final records = (results[0] as List)
        .whereType<Map<String, dynamic>>()
        .map(AttendanceRecord.fromJson)
        .toList();

      final summary = results[1] != null
      ? DailySummary.fromJson(results[1])
      : const DailySummary();

      final shifts = (results[2] as List)
        .whereType<Map<String, dynamic>>()
        .map(ShiftType.fromJson)
        .toList();

      state = state.copyWith(
        isLoading: false,
        records: records,
        summary: summary,
        shifts: shifts,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<Map<String, dynamic>?> getPaidLeaveBalance(int employeeId) async {
    try {
      return await _repository.getPaidLeaveBalance(employeeId);
    } catch (e) {
      return null;
    }
  }
}

final attendanceProvider = StateNotifierProvider<AttendanceNotifier, AttendanceState>((ref) {
  final notifier = AttendanceNotifier(ref.read(attendanceRepositoryProvider));
  ref.listen<int>(appRefreshProvider, (_, __) {
    if (notifier._currentDate.isNotEmpty) {
      notifier.loadAllData(notifier._currentDate);  // Reloads the same date when app refreshed
    }
  });
  return notifier;
});
