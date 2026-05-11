import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/app_refresh_provider.dart';
import '../../../../core/providers/session_ui_state_provider.dart';
import '../providers/employee_provider.dart';
import '../widgets/employee_stats_card.dart';
import '../widgets/employees_tab.dart';
import '../widgets/departments_tab.dart';
import '../widgets/leaves_tab.dart';
import '../widgets/add_employee_sheet.dart';
import '../widgets/edit_employee_sheet.dart';
import '../widgets/employee_detail_sheet.dart';

class EmployeeListScreen extends ConsumerStatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  ConsumerState<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends ConsumerState<EmployeeListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedDepartment = 'all';
  int _lastRefreshTrigger = 0;

  @override
  void initState() {
    super.initState();
    final initialIndex = ref.read(sessionTabIndexProvider('employees')).clamp(0, 2).toInt();
    _tabController = TabController(length: 3, vsync: this, initialIndex: initialIndex);
    _tabController.addListener(() {
      ref.read(sessionTabIndexProvider('employees').notifier).state = _tabController.index;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(employeeProvider.notifier).loadAllData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(employeeProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 800;

    if (state.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null) {
      return Scaffold(
        body: Center(child: Text(state.error!)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => ref.read(employeeProvider.notifier).loadAllData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EmployeeStatsCard(stats: state.stats, isSmallScreen: isSmallScreen),
              const SizedBox(height: 20),
              _EmployeeTabSection(
                tabController: _tabController,
                state: state,
                isSmallScreen: isSmallScreen,
                selectedDepartment: _selectedDepartment,
                onDepartmentChanged: (dept) => setState(() => _selectedDepartment = dept),
                onEmployeeTap: _showEmployeeDetail,
                onEditEmployee: _showEditDialog,
                onApproveLeave: _approveLeave,
                onRejectLeave: _rejectLeave,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _AddEmployeeFAB(onPressed: _showAddDialog),
    );
  }

  // ─── Actions ─────────────────────────────────────────────────────────────────

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEmployeeSheet(
        onSave: (data) async {
          final success = await ref.read(employeeProvider.notifier).createEmployee(data);
          if (success && mounted) {
            if (context.mounted) Navigator.pop(context);
            _showSnackBar('Employee added successfully', AppColors.success);
          }
        },
      ),
    );
  }

  void _showEmployeeDetail(Employee employee) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EmployeeDetailSheet(
        employee: employee,
        onEdit: () => _showEditDialog(employee),
      ),
    );
  }

  void _showEditDialog(Employee employee) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditEmployeeSheet(
        employee: employee,
        onSave: (data) async {
          final success = await ref.read(employeeProvider.notifier).updateEmployee(employee.id, data);
          if (success && mounted) {
            if (context.mounted) Navigator.pop(context);
            _showSnackBar('Employee updated successfully', AppColors.success);
          }
        },
      ),
    );
  }

  void _approveLeave(int id) async {
    await ref.read(employeeProvider.notifier).approveLeave(id);
    if (mounted) {
      _showSnackBar('Leave approved', AppColors.success);
    }
  }

  void _rejectLeave(int id) async {
    await ref.read(employeeProvider.notifier).rejectLeave(id);
    if (mounted) {
      _showSnackBar('Leave rejected', AppColors.error);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// ─── Tab Section (extracted widget) ───────────────────────────────────────────

class _EmployeeTabSection extends StatelessWidget {
  final TabController tabController;
  final EmployeeState state;
  final bool isSmallScreen;
  final String selectedDepartment;
  final ValueChanged<String> onDepartmentChanged;
  final Function(Employee) onEmployeeTap;
  final Function(Employee) onEditEmployee;
  final Function(int) onApproveLeave;
  final Function(int) onRejectLeave;

  const _EmployeeTabSection({
    required this.tabController,
    required this.state,
    required this.isSmallScreen,
    required this.selectedDepartment,
    required this.onDepartmentChanged,
    required this.onEmployeeTap,
    required this.onEditEmployee,
    required this.onApproveLeave,
    required this.onRejectLeave,
  });

  @override
  Widget build(BuildContext context) {
    final pendingCount = state.pendingLeaves.length;
    final employeeCount = state.employees.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab bar
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: TabBar(
            controller: tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicator: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
            padding: const EdgeInsets.all(4),
            tabs: [
              _TabItem(label: 'Employees', count: employeeCount, icon: Icons.people_rounded),
              _TabItem(label: 'Departments', count: null, icon: Icons.business_rounded),
              _TabItem(label: 'Leaves', count: pendingCount, icon: Icons.event_note_rounded, countColor: pendingCount > 0 ? AppColors.warning : null),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Tab content
        SizedBox(
          height: 580,
          child: TabBarView(
            controller: tabController,
            children: [
              EmployeesTab(
                isSmallScreen: isSmallScreen,
                selectedDepartment: selectedDepartment,
                onDepartmentChanged: onDepartmentChanged,
                onEmployeeTap: onEmployeeTap,
                onEditEmployee: onEditEmployee,
              ),
              DepartmentsTab(isSmallScreen: isSmallScreen),
              LeavesTab(
                isSmallScreen: isSmallScreen,
                onApproveLeave: onApproveLeave,
                onRejectLeave: onRejectLeave,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Tab Item ─────────────────────────────────────────────────────────────────

class _TabItem extends StatelessWidget {
  final String label;
  final int? count;
  final IconData icon;
  final Color? countColor;

  const _TabItem({required this.label, this.count, required this.icon, this.countColor});

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: 44,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15),
          const SizedBox(width: 5),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          if (count != null && count! > 0) ...[
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: (countColor ?? AppColors.primary).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: countColor ?? AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── FAB ─────────────────────────────────────────────────────────────────────

class _AddEmployeeFAB extends StatelessWidget {
  final VoidCallback onPressed;
  const _AddEmployeeFAB({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_add_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Add Employee', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
