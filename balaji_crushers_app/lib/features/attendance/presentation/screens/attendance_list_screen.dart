import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/app_refresh_provider.dart';
import '../providers/attendance_provider.dart';
import '../../utils/attendance_date_utils.dart';
import '../../../employee/presentation/providers/employee_provider.dart';
import '../widgets/widgets.dart';
import '../widgets/sheets/attendance_sheet.dart';

class AttendanceListScreen extends ConsumerStatefulWidget {
  const AttendanceListScreen({super.key});

  @override
  ConsumerState<AttendanceListScreen> createState() =>
      _AttendanceListScreenState();
}

class _AttendanceListScreenState extends ConsumerState<AttendanceListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = attendanceTodayIstDate();
  final Map<int, String> _selectedEmployees = {};

  // ── Search ────────────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() { if (mounted) setState(() {}); });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    final date = attendanceDateParam(_selectedDate);
    ref.read(attendanceProvider.notifier).loadAllData(date);
    final empState = ref.read(employeeProvider);
    if (empState.employees.isEmpty) {
      ref.read(employeeProvider.notifier).loadEmployees();
    }
  }

  bool get _canMarkPresent  => _selectedEmployees.isNotEmpty;
  bool get _canMarkHalfDay  => _selectedEmployees.isNotEmpty;

  bool get _canMarkAbsent {
    if (_selectedEmployees.isEmpty) return false;
    final empState = ref.read(employeeProvider);
    for (final empId in _selectedEmployees.keys) {
      final emp = empState.employees.where((e) => e.id == empId).cast<dynamic>().firstWhere((e) => true, orElse: () => null);
      final balance = emp?.paidLeaveBalance ?? 15;
      if (balance > 0) return false;
    }
    return true;
  }

  bool get _canMarkLeave {
    if (_selectedEmployees.isEmpty) return false;
    final empState = ref.read(employeeProvider);
    for (final empId in _selectedEmployees.keys) {
      final emp = empState.employees.where((e) => e.id == empId).cast<dynamic>().firstWhere((e) => true, orElse: () => null);
      final balance = emp?.paidLeaveBalance ?? 15;
      if (balance <= 0) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(attendanceProvider);

    // Only show full-screen spinner on the very first load (no records yet).
    // During a reload triggered by mark/update, keep the existing UI visible.
    if (state.isLoading && state.records.isEmpty && state.summary == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null && state.records.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(state.error!, style: const TextStyle(color: AppColors.error)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
 
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Subtle reload indicator shown while data is refreshing after mark/update
          if (state.isLoading && state.records.isNotEmpty)
            LinearProgressIndicator(
              minHeight: 3,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              color: AppColors.primary,
            ),

          // ── Top section with gradient background ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                DateSelector(
                  selectedDate: _selectedDate,
                  onDateChanged: (date) {
                    setState(() {
                      _selectedDate = date;
                      _selectedEmployees.clear(); // Reset selection on date change
                    });
                    _loadData();
                  },
                  onTodayPressed: () {
                    setState(() {
                      _selectedDate = attendanceTodayIstDate();
                      _selectedEmployees.clear(); // Reset selection on date change
                    });
                    _loadData();
                  },
                ),
                const SizedBox(height: 16),
                AttendanceSummaryRow(
                  presentCount: state.summary?.presentCount ?? 0,
                  absentCount: state.summary?.absentCount ?? 0,
                  halfDayCount: state.summary?.halfDayCount ?? 0,
                  onLeaveCount: state.summary?.onLeaveCount ?? 0,
                ),
                const SizedBox(height: 12),

                // Tab bar
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
                  tabs: [
                    const Tab(text: 'All Attendance'),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Quick Mark'),
                          if (_selectedEmployees.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_selectedEmployees.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Tab content ──
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllAttendanceTab(),
                _buildQuickMarkTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showMarkAttendanceDialog,
        backgroundColor: AppColors.primary,
        elevation: 3,
        icon: const Icon(Icons.edit_calendar_rounded, color: Colors.white),
        label: const Text(
          'Mark Attendance',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // ── All Attendance Tab ────────────────────────────────────────────

  Widget _buildAllAttendanceTab() {
    final state = ref.watch(attendanceProvider);

    if (state.isLoading && state.records.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.records.isEmpty) {
      return EmptyState(
        icon: Icons.today_rounded,
        message: 'No records for this date',
        subtitle: 'Tap "Mark Attendance" to add records',
        action: TextButton.icon(
          onPressed: _showMarkAttendanceDialog,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Mark Now'),
        ),
      );
    }

    // Filter by search query
    final q = _searchQuery.toLowerCase();
    final filtered = q.isEmpty
        ? state.records
        : state.records.where((r) =>
            r.employeeName.toLowerCase().contains(q) ||
            r.employeeCode.toLowerCase().contains(q)).toList();

    return Column(
      children: [
        // ── Search bar + Delete All row ──────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: _AttendanceSearchBar(
                  controller: _searchController,
                  query: _searchQuery,
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                  onClear: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
              ),
              const SizedBox(width: 8),
              // ── Delete All button ─────────────────────────────
              Tooltip(
                message: 'Delete all attendance for this date',
                child: OutlinedButton.icon(
                  onPressed: () => _confirmDeleteAll(state.records.length),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error, width: 1.2),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                  label: const Text('Delete All',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),

        // ── Results list ───────────────────────────────
        Expanded(
          child: filtered.isEmpty
              ? EmptyState(
                  icon: Icons.search_off_rounded,
                  message: q.isNotEmpty
                      ? 'No results for "$_searchQuery"'
                      : 'No records for this date',
                  subtitle: q.isNotEmpty
                      ? 'Try a different name or code'
                      : 'Tap "Mark Attendance" to add records',
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    _loadData();
                    await Future.delayed(const Duration(milliseconds: 300));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final record = filtered[index];
                      return _AttendanceCard(
                        record: record,
                        onTap: () => _showUpdateDialog(record),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  // ── Quick Mark Tab ────────────────────────────────────────────────

  Widget _buildQuickMarkTab() {
    final employeeState  = ref.watch(employeeProvider);
    final attendanceState = ref.watch(attendanceProvider);

    final markedIds = attendanceState.records.map((r) => r.employeeId).toSet();
    final unmarked  = employeeState.employees
        .where((e) => !markedIds.contains(e.id) && (e.isActive ?? false))
        .toList();

    if (unmarked.isEmpty) {
      return const EmptyState(
        icon: Icons.check_circle_rounded,
        message: 'All employees marked!',
        subtitle: 'Everyone has been marked for today',
      );
    }

    final allSelected = unmarked.every((e) => _selectedEmployees.containsKey(e.id));

    // Apply search filter
    final q = _searchQuery.toLowerCase();
    final visibleUnmarked = q.isEmpty
        ? unmarked
        : unmarked.where((e) =>
            e.fullName.toLowerCase().contains(q) ||
            e.employeeCode.toLowerCase().contains(q)).toList();

    return Column(
      children: [
        // ── Action toolbar ────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Select all checkbox (acts on visible filtered list)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (allSelected) {
                          _selectedEmployees.clear();
                        } else {
                          for (final e in visibleUnmarked) {
                            _selectedEmployees[e.id] = e.fullName;
                          }
                        }
                      });
                    },
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: allSelected ? AppColors.primary : Colors.transparent,
                            border: Border.all(
                              color: allSelected ? AppColors.primary : Colors.grey.shade400,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: allSelected
                              ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Select All',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Count pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${visibleUnmarked.length} pending • ${_selectedEmployees.length} selected',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Mark buttons
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    QuickMarkButton(
                      label: 'Present',
                      status: 'present',
                      enabled: _canMarkPresent,
                      color: AppColors.success,
                      onPressed: () => _markSelectedWithStatus(_selectedEmployees, 'present'),
                    ),
                    const SizedBox(width: 8),
                    QuickMarkButton(
                      label: 'Half Day',
                      status: 'half_day',
                      enabled: _canMarkHalfDay,
                      color: AppColors.warning,
                      onPressed: () => _markSelectedWithStatus(_selectedEmployees, 'half_day'),
                    ),
                    const SizedBox(width: 8),
                    QuickMarkButton(
                      label: 'On Leave',
                      status: 'leave',
                      enabled: _canMarkLeave,
                      color: AppColors.info,
                      onPressed: () => _markSelectedWithStatus(_selectedEmployees, 'leave'),
                    ),
                    const SizedBox(width: 8),
                    QuickMarkButton(
                      label: 'Absent',
                      status: 'absent',
                      enabled: _canMarkAbsent,
                      color: AppColors.error,
                      onPressed: () => _markSelectedWithStatus(_selectedEmployees, 'absent'),
                    ),
                  ],
                ),
              ),
              // ── Search bar ──────────────────────────────
              const SizedBox(height: 10),
              _AttendanceSearchBar(
                controller: _searchController,
                query: _searchQuery,
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
                onClear: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              ),
            ],
          ),
        ),

        // ── Employee list (filtered) ─────────────────────
        Expanded(
          child: visibleUnmarked.isEmpty
              ? EmptyState(
                  icon: q.isNotEmpty
                      ? Icons.search_off_rounded
                      : Icons.check_circle_rounded,
                  message: q.isNotEmpty
                      ? 'No results for "$_searchQuery"'
                      : 'All employees marked!',
                  subtitle: q.isNotEmpty
                      ? 'Try a different name'
                      : 'Everyone has been marked for today',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: visibleUnmarked.length,
                  itemBuilder: (context, index) {
                    final emp = visibleUnmarked[index];
                    final isSelected = _selectedEmployees.containsKey(emp.id);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedEmployees.remove(emp.id);
                          } else {
                            _selectedEmployees[emp.id] = emp.fullName;
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.06)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.4)
                                : Colors.grey.shade200,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              // Avatar
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isSelected
                                        ? [AppColors.primary, AppColors.primaryLight]
                                        : [Colors.grey.shade300, Colors.grey.shade200],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    emp.firstName[0].toUpperCase(),
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey.shade600,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      emp.fullName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${emp.employeeCode} • ${emp.departmentName ?? "No dept"}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Checkbox
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.grey.shade400,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check_rounded,
                                        size: 14, color: Colors.white)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ── Actions ───────────────────────────────────────────────────────

  void _markSelectedWithStatus(Map<int, String> employees, String status) async {
    final records = employees.keys.map((id) {
      final data = <String, dynamic>{
        'employee_id': id,
        'date': attendanceDateParam(_selectedDate),
        'status': status,
      };
      if (status == 'present') {
        data['check_in']  = '09:00:00';
        data['check_out'] = '18:00:00';
      } else if (status == 'half_day') {
        data['check_in']  = '09:00:00';
        data['check_out'] = '13:00:00';
      }
      return data;
    }).toList();

    if (status == 'leave') {
      final futures = employees.entries.map((entry) async {
        final balance = await ref
            .read(attendanceProvider.notifier)
            .getPaidLeaveBalance(entry.key);

        final remaining = _parseCount(balance?['leaves_remaining']);
        return remaining > 0 ? entry : null;
      }).toList();

      final results = await Future.wait(futures);

      final withLeave = <int, String>{};
      for (final entry in results) {
        if (entry != null) {
          withLeave[entry.key] = entry.value;
        }
      }

      if (withLeave.length < employees.length && mounted) {
        final missing = employees.length - withLeave.length;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$missing employee(s) have no leave balance'),
          backgroundColor: AppColors.warning,
        ));
      }
      if (withLeave.isEmpty) return;

      final leaveRecords = withLeave.keys
          .map((id) => <String, dynamic>{
                'employee_id': id,
                'date': attendanceDateParam(_selectedDate),
                'status': 'leave',
              })
          .toList();
      final success = await ref
          .read(attendanceProvider.notifier)
          .bulkMarkAttendance(leaveRecords);
      if (success && mounted) {
        setState(() => _selectedEmployees.clear());
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${withLeave.length} employee(s) marked as on leave'),
          backgroundColor: AppColors.info,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
      return;
    }

    final success = await ref
        .read(attendanceProvider.notifier)
        .bulkMarkAttendance(records);

    if (success && mounted) {
      final count = employees.length;
      setState(() => _selectedEmployees.clear());

      final (text, color) = switch (status) {
        'present'  => ('present', AppColors.success),
        'absent'   => ('absent', AppColors.error),
        'half_day' => ('half day', AppColors.warning),
        'leave'    => ('on leave', AppColors.info),
        _          => (status, AppColors.primary),
      };

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$count employee${count > 1 ? 's' : ''} marked as $text'),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  int _parseCount(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  // ── Delete all for date confirmation ──────────────────────────────

  Future<void> _confirmDeleteAll(int count) async {
    final dateLabel = DateFormat('d MMMM yyyy').format(_selectedDate);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_sweep_rounded,
                  color: AppColors.error, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Delete All Attendance',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(
                color: Colors.black87, fontSize: 14, height: 1.5),
            children: [
              const TextSpan(text: 'This will permanently delete '),
              TextSpan(
                text: '$count record${count != 1 ? "s" : ""}',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.error),
              ),
              const TextSpan(text: ' for '),
              TextSpan(
                text: dateLabel,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const TextSpan(text: '.\n\nThis action cannot be undone.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success =
          await ref.read(attendanceProvider.notifier).deleteAllForDate();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? '$count record${count != 1 ? "s" : ""} deleted for $dateLabel'
              : 'Failed to delete attendance'),
          backgroundColor: success ? AppColors.error : AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showMarkAttendanceDialog() {
    final state = ref.read(attendanceProvider);
    final markedIds = state.records.map((r) => r.employeeId).toSet();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MarkAttendanceSheet(
        date: _selectedDate,
        markedEmployeeIds: markedIds,
        onSave: (data) async {
          final success = await ref
              .read(attendanceProvider.notifier)
              .markAttendance(data);
          if (success && mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Attendance marked successfully'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  void _showUpdateDialog(AttendanceRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UpdateAttendanceSheet(
        record: record,
        onUpdate: (data) async {
          final dataWithDate = <String, dynamic>{...data, 'date': record.date};
          final success = await ref
              .read(attendanceProvider.notifier)
              .updateAttendance(record.id, dataWithDate);
          if (success && mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Attendance updated'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        },
        onDelete: () async {
          await ref
              .read(attendanceProvider.notifier)
              .deleteAttendance(record.id);
          if (mounted) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}

// ── Attendance Card ───────────────────────────────────────────────────

class _AttendanceCard extends StatelessWidget {
  final AttendanceRecord record;
  final VoidCallback onTap;

  const _AttendanceCard({required this.record, required this.onTap});

  Color _statusColor(String s) {
    switch (s) {
      case 'present':  return AppColors.success;
      case 'absent':   return AppColors.error;
      case 'half_day': return AppColors.warning;
      case 'leave':    return AppColors.info;
      case 'holiday':  return AppColors.accent;
      default:         return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(record.status);
    final initials = record.employeeName.trim().split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            // Color accent bar
            Container(
              height: 4,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.4)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.employeeName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.badge_outlined, size: 11, color: AppColors.textSecondary),
                            const SizedBox(width: 3),
                            Text(
                              record.employeeCode,
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            if (record.departmentName != null) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.business_outlined, size: 11, color: AppColors.textSecondary),
                              const SizedBox(width: 3),
                              Text(
                                record.departmentName!,
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ],
                        ),
                        if (record.checkIn != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.access_time_rounded, size: 11, color: color),
                              const SizedBox(width: 3),
                              Text(
                                'In: ${AttendanceRecord.to12Hour(record.checkIn)}'
                                '${record.checkOut != null ? '  •  Out: ${AttendanceRecord.to12Hour(record.checkOut)}' : ''}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Right side
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      StatusBadge(status: record.status),
                      if (record.overtimeHours > 0) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+${record.overtimeHours}h OT',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Icon(Icons.edit_outlined, size: 14, color: Colors.grey.shade400),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared search bar ──────────────────────────────────────────────────────

class _AttendanceSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _AttendanceSearchBar({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search employee…',
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        prefixIcon: const Icon(
            Icons.search_rounded, size: 20, color: AppColors.textSecondary),
        suffixIcon: query.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: onClear,
              )
            : null,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
