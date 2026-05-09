import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../providers/attendance_provider.dart';
import '../../../utils/attendance_date_utils.dart';
import '../../../../employee/presentation/providers/employee_provider.dart';
import '../time_input_field.dart';

class MarkAttendanceSheet extends ConsumerStatefulWidget {
  final DateTime date;
  final Set<int> markedEmployeeIds;
  final Function(Map<String, dynamic>) onSave;

  const MarkAttendanceSheet({
    super.key,
    required this.date,
    required this.markedEmployeeIds,
    required this.onSave,
  });

  @override
  ConsumerState<MarkAttendanceSheet> createState() =>
      _MarkAttendanceSheetState();
}

class _MarkAttendanceSheetState extends ConsumerState<MarkAttendanceSheet> {
  int? _selectedEmployeeId;
  String _status = 'present';
  final _checkInController  = TextEditingController(text: '09:00');
  final _checkOutController = TextEditingController(text: '06:00');
  final _checkInKey  = GlobalKey<TimeInputFieldState>();
  final _checkOutKey = GlobalKey<TimeInputFieldState>();
  final _overtimeController = TextEditingController(text: '0');
  final _notesController    = TextEditingController();
  Map<String, dynamic>? _leaveBalance;
  bool _loadingLeave = false;
  bool _isSaving = false;

  bool get _isTimeDisabled     => _status == 'absent' || _status == 'leave' || _status == 'holiday';
  bool get _isOvertimeDisabled => _status != 'present';
  bool get _hasLeaveBalance {
    if (_leaveBalance == null) return true;
    return _parseCount(_leaveBalance!['leaves_remaining']) > 0;
  }

  List<DropdownMenuItem<String>> get _statusItems {
    if (_hasLeaveBalance || _status == 'leave') {
      return const [
        DropdownMenuItem(value: 'present',  child: Text('Present')),
        DropdownMenuItem(value: 'half_day', child: Text('Half Day')),
        DropdownMenuItem(value: 'leave',    child: Text('On Leave')),
      ];
    }
    return const [
      DropdownMenuItem(value: 'present',  child: Text('Present')),
      DropdownMenuItem(value: 'half_day', child: Text('Half Day')),
      DropdownMenuItem(value: 'absent',   child: Text('Absent')),
    ];
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(employeeProvider.notifier).loadEmployees());
  }

  @override
  void dispose() {
    _checkInController.dispose();
    _checkOutController.dispose();
    _overtimeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int _parseCount(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  Future<void> _loadLeaveBalance(int id) async {
    setState(() { _loadingLeave = true; _leaveBalance = null; });
    try {
      final b = await ref.read(attendanceProvider.notifier).getPaidLeaveBalance(id);
      if (mounted) setState(() { _leaveBalance = b; _loadingLeave = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingLeave = false);
    }
  }

  void _onStatusChanged(String status) {
    setState(() {
      _status = status;
      if (_isTimeDisabled) {
        _checkInController.text  = '00:00';
        _checkOutController.text = '00:00';
        _overtimeController.text = '0';
      } else if (status == 'present') {
        _checkInController.text  = '09:00';
        _checkOutController.text = '06:00';
      } else if (status == 'half_day') {
        _checkInController.text  = '09:00';
        _checkOutController.text = '01:00';
      }
    });
    if (status == 'leave' && _selectedEmployeeId != null) {
      _loadLeaveBalance(_selectedEmployeeId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeeState    = ref.watch(employeeProvider);
    final unmarkedEmployees = employeeState.employees
        .where((e) => !widget.markedEmployeeIds.contains(e.id))
        .toList();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Gradient header ──────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.edit_calendar_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mark Attendance',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                        Text(
                          DateFormat('dd MMM yyyy').format(widget.date),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Form body ────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: unmarkedEmployees.isEmpty
                  ? _buildAllMarked()
                  : _buildForm(unmarkedEmployees),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllMarked() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.check_circle_rounded, size: 52, color: AppColors.success),
            SizedBox(height: 12),
            Text(
              'All employees marked!',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            SizedBox(height: 4),
            Text(
              'Everyone has been marked for today',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(List unmarkedEmployees) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Employee dropdown
        _FieldLabel('Select Employee *'),
        DropdownButtonFormField<int>(
          value: _selectedEmployeeId,
          decoration: _inputDec('Choose employee', prefixIcon: Icons.person_outline),
          items: unmarkedEmployees.map<DropdownMenuItem<int>>((e) =>
              DropdownMenuItem(value: e.id, child: Text(e.fullName))).toList(),
          onChanged: (v) {
            setState(() => _selectedEmployeeId = v);
            if (v != null) _loadLeaveBalance(v);
          },
        ),
        const SizedBox(height: 14),

        // Status dropdown
        _FieldLabel('Attendance Status'),
        DropdownButtonFormField<String>(
          value: _status,
          decoration: _inputDec('Status', prefixIcon: Icons.toggle_on_outlined),
          items: _statusItems,
          onChanged: (v) => _onStatusChanged(v!),
        ),
        const SizedBox(height: 14),

        // Leave balance info
        if (_status == 'leave') ...[
          _LeaveBalanceWidget(
            isLoading: _loadingLeave,
            leaveBalance: _leaveBalance,
            parseCount: _parseCount,
          ),
          const SizedBox(height: 14),
        ],

        // Time fields
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('Check In'),
                  Opacity(
                    opacity: _isTimeDisabled ? 0.4 : 1.0,
                    child: IgnorePointer(
                      ignoring: _isTimeDisabled,
                      child: TimeInputField(
                        key: _checkInKey,
                        controller: _checkInController,
                        label: '',
                        defaultPeriod: 'AM',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('Check Out'),
                  Opacity(
                    opacity: _isTimeDisabled ? 0.4 : 1.0,
                    child: IgnorePointer(
                      ignoring: _isTimeDisabled,
                      child: TimeInputField(
                        key: _checkOutKey,
                        controller: _checkOutController,
                        label: '',
                        defaultPeriod: 'PM',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Overtime
        _FieldLabel('Overtime Hours'),
        Opacity(
          opacity: _isOvertimeDisabled ? 0.4 : 1.0,
          child: IgnorePointer(
            ignoring: _isOvertimeDisabled,
            child: TextField(
              controller: _overtimeController,
              keyboardType: TextInputType.number,
              decoration: _inputDec('0', prefixIcon: Icons.schedule_rounded),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Notes
        _FieldLabel('Notes (Optional)'),
        TextField(
          controller: _notesController,
          maxLines: 2,
          decoration: _inputDec('Any remarks...', prefixIcon: Icons.notes_rounded),
        ),
        const SizedBox(height: 24),

        // Submit button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _selectedEmployeeId == null || _isSaving
                ? null
                : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'MARK ATTENDANCE',
                    style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
                  ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _submit() {
    setState(() => _isSaving = true);
    widget.onSave({
      'employee_id':   _selectedEmployeeId,
      'date':          attendanceDateParam(widget.date),
      'status':        _status,
      'check_in':      _isTimeDisabled ? null : (_checkInKey.currentState?.time24Hour  ?? '09:00:00'),
      'check_out':     _isTimeDisabled ? null : (_checkOutKey.currentState?.time24Hour ?? '18:00:00'),
      'overtime_hours': _isOvertimeDisabled ? 0 : double.tryParse(_overtimeController.text) ?? 0,
      'notes':         _notesController.text.isEmpty ? null : _notesController.text,
    });
  }
}

// ── Update Attendance Sheet ───────────────────────────────────────────

class UpdateAttendanceSheet extends ConsumerStatefulWidget {
  final AttendanceRecord record;
  final Function(Map<String, dynamic>) onUpdate;
  final VoidCallback onDelete;

  const UpdateAttendanceSheet({
    super.key,
    required this.record,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  ConsumerState<UpdateAttendanceSheet> createState() =>
      _UpdateAttendanceSheetState();
}

class _UpdateAttendanceSheetState extends ConsumerState<UpdateAttendanceSheet> {
  late String _status;
  late TextEditingController _checkInController;
  late TextEditingController _checkOutController;
  late TextEditingController _overtimeController;
  late TextEditingController _notesController;
  final _checkInKey  = GlobalKey<TimeInputFieldState>();
  final _checkOutKey = GlobalKey<TimeInputFieldState>();
  Map<String, dynamic>? _leaveBalance;
  bool _loadingLeave = false;
  bool _isSaving = false;

  bool get _isTimeDisabled     => _status == 'absent' || _status == 'leave' || _status == 'holiday';
  bool get _isOvertimeDisabled => _status != 'present';
  bool get _hasLeaveBalance {
    if (_leaveBalance == null) return true;
    return _parseCount(_leaveBalance!['leaves_remaining']) > 0;
  }

  List<DropdownMenuItem<String>> get _statusItems {
    if (_hasLeaveBalance || _status == 'leave') {
      return const [
        DropdownMenuItem(value: 'present',  child: Text('Present')),
        DropdownMenuItem(value: 'half_day', child: Text('Half Day')),
        DropdownMenuItem(value: 'leave',    child: Text('On Leave')),
      ];
    }
    return const [
      DropdownMenuItem(value: 'present',  child: Text('Present')),
      DropdownMenuItem(value: 'half_day', child: Text('Half Day')),
      DropdownMenuItem(value: 'absent',   child: Text('Absent')),
    ];
  }

  String _to12Hr(String? t) {
    if (t == null || t.isEmpty) return '';
    final parts = t.split(':');
    int h = int.tryParse(parts[0]) ?? 0;
    int m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    if (h == 0) return '12:${m.toString().padLeft(2, '0')}';
    if (h > 12) h -= 12;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _status = widget.record.status;
    _checkInController  = TextEditingController(text: _to12Hr(widget.record.checkIn));
    _checkOutController = TextEditingController(text: _to12Hr(widget.record.checkOut));
    _overtimeController = TextEditingController(text: widget.record.overtimeHours.toString());
    _notesController    = TextEditingController(text: widget.record.notes ?? '');
    Future.microtask(() => _loadLeaveBalance(widget.record.employeeId));
  }

  @override
  void dispose() {
    _checkInController.dispose();
    _checkOutController.dispose();
    _overtimeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int _parseCount(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  Future<void> _loadLeaveBalance(int id) async {
    setState(() { _loadingLeave = true; _leaveBalance = null; });
    try {
      final b = await ref.read(attendanceProvider.notifier).getPaidLeaveBalance(id);
      if (mounted) setState(() { _leaveBalance = b; _loadingLeave = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingLeave = false);
    }
  }

  void _onStatusChanged(String status) {
    setState(() {
      _status = status;
      if (_isTimeDisabled) {
        _checkInController.text  = '00:00';
        _checkOutController.text = '00:00';
        _overtimeController.text = '0';
      } else if (status == 'present') {
        _checkInController.text  = '09:00';
        _checkOutController.text = '06:00';
      } else if (status == 'half_day') {
        _checkInController.text  = '09:00';
        _checkOutController.text = '01:00';
      }
    });
    if (status == 'leave') _loadLeaveBalance(widget.record.employeeId);
  }

  @override
  Widget build(BuildContext context) {
    final initials = widget.record.employeeName.trim()
        .split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.record.employeeName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            widget.record.employeeCode,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Delete button in header
                    GestureDetector(
                      onTap: widget.onDelete,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Form ────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('Status'),
                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: _inputDec('Status', prefixIcon: Icons.toggle_on_outlined),
                    items: _statusItems,
                    onChanged: (v) => _onStatusChanged(v!),
                  ),
                  const SizedBox(height: 14),

                  if (_status == 'leave') ...[
                    _LeaveBalanceWidget(
                      isLoading: _loadingLeave,
                      leaveBalance: _leaveBalance,
                      parseCount: _parseCount,
                    ),
                    const SizedBox(height: 14),
                  ],

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FieldLabel('Check In'),
                            Opacity(
                              opacity: _isTimeDisabled ? 0.4 : 1.0,
                              child: IgnorePointer(
                                ignoring: _isTimeDisabled,
                                child: TimeInputField(
                                  key: _checkInKey,
                                  controller: _checkInController,
                                  label: '',
                                  defaultPeriod: 'AM',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FieldLabel('Check Out'),
                            Opacity(
                              opacity: _isTimeDisabled ? 0.4 : 1.0,
                              child: IgnorePointer(
                                ignoring: _isTimeDisabled,
                                child: TimeInputField(
                                  key: _checkOutKey,
                                  controller: _checkOutController,
                                  label: '',
                                  defaultPeriod: 'PM',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _FieldLabel('Overtime Hours'),
                  Opacity(
                    opacity: _isOvertimeDisabled ? 0.4 : 1.0,
                    child: IgnorePointer(
                      ignoring: _isOvertimeDisabled,
                      child: TextField(
                        controller: _overtimeController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDec('0', prefixIcon: Icons.schedule_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  _FieldLabel('Notes'),
                  TextField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: _inputDec('Any remarks...', prefixIcon: Icons.notes_rounded),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'UPDATE ATTENDANCE',
                              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    setState(() => _isSaving = true);
    widget.onUpdate({
      'status':         _status,
      'check_in':       _isTimeDisabled ? null : (_checkInKey.currentState?.time24Hour  ?? '09:00:00'),
      'check_out':      _isTimeDisabled ? null : (_checkOutKey.currentState?.time24Hour ?? '18:00:00'),
      'overtime_hours': _isOvertimeDisabled ? 0 : double.tryParse(_overtimeController.text) ?? 0,
      'notes':          _notesController.text.isEmpty ? null : _notesController.text,
    });
  }
}

// ── Shared helpers ────────────────────────────────────────────────────

class _LeaveBalanceWidget extends StatelessWidget {
  final bool isLoading;
  final Map<String, dynamic>? leaveBalance;
  final int Function(dynamic) parseCount;

  const _LeaveBalanceWidget({
    required this.isLoading,
    required this.leaveBalance,
    required this.parseCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
      ),
      child: isLoading
          ? const Center(
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Row(
              children: [
                const Icon(Icons.event_available_rounded, color: AppColors.info, size: 18),
                const SizedBox(width: 8),
                Text(
                  leaveBalance == null
                      ? 'Select employee to see leave balance'
                      : 'Paid Leaves: ${parseCount(leaveBalance!['leaves_remaining'])} / ${parseCount(leaveBalance!['total_leaves'])} remaining',
                  style: const TextStyle(
                    color: AppColors.info,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
    );
  }
}

Widget _FieldLabel(String label) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.2,
      ),
    ),
  );
}

InputDecoration _inputDec(
  String hint, {
  IconData? prefixIcon,
  String? prefixText,
  String? suffixText,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.black26, fontSize: 13),
    prefixText: prefixText,
    suffixText: suffixText,
    prefixIcon: prefixIcon != null
        ? Icon(prefixIcon, size: 18, color: AppColors.textSecondary)
        : null,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    isDense: true,
    filled: true,
    fillColor: Colors.grey.shade50,
  );
}
