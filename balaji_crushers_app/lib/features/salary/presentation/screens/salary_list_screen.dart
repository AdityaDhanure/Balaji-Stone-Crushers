import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:balaji_crushers_app/core/constants/app_colors.dart';
import 'package:balaji_crushers_app/core/providers/app_refresh_provider.dart';
import 'package:balaji_crushers_app/features/salary/data/models/salary_models.dart';
import 'package:balaji_crushers_app/features/salary/data/repositories/salary_repository.dart';
import 'package:balaji_crushers_app/features/salary/presentation/providers/salary_provider.dart';
import 'package:balaji_crushers_app/features/salary/presentation/widgets/widgets.dart';


class SalaryListScreen extends ConsumerStatefulWidget {
  const SalaryListScreen({super.key});

  @override
  ConsumerState<SalaryListScreen> createState() => _SalaryListScreenState();
}

class _SalaryListScreenState extends ConsumerState<SalaryListScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late TabController _componentsTabController;
  SalaryPeriod? _selectedPeriod;
  List<EmployeeSalary> _employees = [];
  List<Department> _departments = [];

  EmployeeSalary? _selectedEmployee;
  Department? _selectedDepartment;
  String _selectedStatus = 'all';

  // ── Search ────────────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _componentsTabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() { if (mounted) setState(() {}); });
    _componentsTabController.addListener(() { if (mounted) setState(() {}); });
    _loadSupportData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _componentsTabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Data loaders ──────────────────────────────────────────────────

  Future<void> _loadSupportData() async {
    final repo = ref.read(salaryRepositoryProvider);
    try {
      final results = await Future.wait([
        repo.getEmployees(),
        repo.getDepartments(),
      ]);
      if (mounted) {
        setState(() {
          _employees   = results[0] as List<EmployeeSalary>;
          _departments = results[1] as List<Department>;
        });
      }
    } catch (e) {
      _showError('Error loading support data: $e');
    }
  }

  void _onPeriodChanged(SalaryPeriod? period) {
    setState(() {
      _selectedPeriod = period;
    });

    ref.read(salaryNotifierProvider.notifier).loadSlips(
      periodId: period?.id,
      employeeId: _selectedEmployee?.id,
      departmentId: _selectedDepartment?.id,
      status: _selectedStatus == 'all' ? null : _selectedStatus,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showSuccess(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color ?? AppColors.success),
    );
  }

  String _formatNumber(double val) {
    if (val >= 100000) return '${(val / 100000).toStringAsFixed(1)}L';
    if (val >= 1000)   return '${(val / 1000).toStringAsFixed(1)}K';
    return val.toStringAsFixed(0);
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final refreshTrigger = ref.watch(appRefreshProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Period selector (gradient header)
          PeriodSelector(
            selectedPeriod:      _selectedPeriod,
            onPeriodChanged:     _onPeriodChanged,
            onCreatePeriod:      _showCreatePeriodDialog,
            onGenerateIndividual: _showGenerateIndividualDialog,
            onBulkGenerate:      () { if (_selectedPeriod != null) _showGenerateBulkDialog(_selectedPeriod!); },
          ),

          // Tab bar
          Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              tabs: const [
                Tab(text: 'Slips'),
                Tab(text: 'Advances'),
                Tab(text: 'Components'),
                Tab(text: 'Periods'),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSlipsTab(),
                _buildAdvancesTab(),
                _buildDeductionsTab(),
                _buildPeriodsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  // ── FAB ───────────────────────────────────────────────────────────

  Widget _buildFab() {
    switch (_tabController.index) {
      case 1:
        return FloatingActionButton.extended(
          onPressed: _showAdvanceRequestDialog,
          backgroundColor: AppColors.accent,
          icon: const Icon(Icons.request_quote_rounded, color: Colors.white),
          label: const Text('Request Advance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        );
      case 2:
        // Components tab — check inner sub-tab
        if (_componentsTabController.index == 1) {
          return FloatingActionButton.extended(
            onPressed: _showAddEarningDialog,
            backgroundColor: AppColors.success,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text('Add Earning', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          );
        }
        return FloatingActionButton.extended(
          onPressed: _showAddDeductionDialog,
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text('Add Deduction', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        );
      default:
        return FloatingActionButton.extended(
          onPressed: () {
            if (_selectedPeriod == null) {
              _showError('Please select a period first');
              return;
            }
            _showGenerateIndividualDialog();
          },
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.person_add_rounded, color: Colors.white),
          label: const Text('Generate Slip', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        );
    }
  }

  // ── Salary Slips Tab ──────────────────────────────────────────────

  Widget _buildSlipsTab() {
    if (_selectedPeriod == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.calendar_month_rounded, size: 52, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select a salary period',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            const Text(
              'Use the period selector above to get started',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        SalaryFilters(
          employees:          _employees,
          departments:        _departments,
          selectedEmployee:   _selectedEmployee,
          selectedDepartment: _selectedDepartment,
          selectedStatus:     _selectedStatus,
          onEmployeeChanged:  (v) => setState(() => _selectedEmployee   = v),
          onDepartmentChanged:(v) => setState(() => _selectedDepartment = v),
          onStatusChanged:    (v) => setState(() => _selectedStatus     = v),
          onApply: () {
            ref.read(salaryNotifierProvider.notifier).loadSlips(
              periodId: _selectedPeriod?.id,
              employeeId: _selectedEmployee?.id,
              departmentId: _selectedDepartment?.id,
              status: _selectedStatus == 'all' ? null : _selectedStatus,
            );
          },
        ),

        // ── Employee search bar ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v.trim()),
            decoration: InputDecoration(
              hintText: 'Search employee…',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              filled: true,
              fillColor: AppColors.surface,
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
          ),
        ),
        const SizedBox(height: 4),

        Expanded(
          child: Builder(
            builder: (context) {
              final slipsAsync = ref.watch(salaryNotifierProvider);

              return slipsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),

                error: (e, _) => Center(
                  child: Text('Error: $e'),
                ),

                data: (slips) {
                  // Apply client-side name/code search filter
                  final q = _searchQuery.toLowerCase();
                  final filtered = q.isEmpty
                      ? slips
                      : slips.where((s) {
                          final name = s.employeeName.toLowerCase();
                          final code = (s.employeeCode ?? '').toLowerCase();
                          return name.contains(q) || code.contains(q);
                        }).toList();

                  // Summary row (from full list, not filtered)
                  double totalNet = 0;
                  int paid = 0, pending = 0;

                  for (final s in slips) {
                    totalNet += s.netSalary;
                    if (s.status == 'paid') paid++; else pending++;
                  }

                  return Column(
                    children: [
                      // Summary cards
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: AppColors.surface,
                        child: Row(
                          children: [
                            Expanded(
                              child: SummaryCard(
                                title: 'Total Slips',
                                value: '${slips.length}',
                                color: AppColors.primary,
                                icon: Icons.receipt_long_rounded,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SummaryCard(
                                title: 'Net Payable',
                                value: '₹${_formatNumber(totalNet)}',
                                color: AppColors.success,
                                icon: Icons.payments_rounded,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SummaryCard(
                                title: 'Paid',
                                value: '$paid',
                                color: AppColors.info,
                                icon: Icons.check_circle_rounded,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SummaryCard(
                                title: 'Pending',
                                value: '$pending',
                                color: AppColors.warning,
                                icon: Icons.hourglass_bottom_rounded,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // List (filtered)
                      Expanded(
                        child: filtered.isEmpty
                            ? _emptyState(
                                icon: Icons.search_off_rounded,
                                title: q.isNotEmpty ? 'No results for "$_searchQuery"' : 'No salary slips found',
                                subtitle: q.isNotEmpty ? 'Try a different name or code' : 'Generate slips using the button below',
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: filtered.length,
                                itemBuilder: (_, i) {
                                  final slip = filtered[i];
                                  return SalarySlipCard(
                                    slip: slip,
                                    onView: () => _showSlipDetail(slip),
                                    onEdit: () => _showSlipEdit(slip),
                                    onPay:  () => _showPaymentDialog(slip),
                                    onDelete: () => _showDeleteDialog(slip),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Advances Tab ──────────────────────────────────────────────────

  Widget _buildAdvancesTab() {
    final state = ref.watch(advanceNotifierProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => Center(child: Text('Error: $e')),
      data: (advances) {
        if (advances.isEmpty) {
          return _emptyState(
            icon: Icons.request_quote_rounded,
            title: 'No advances yet',
            subtitle: 'Tap the button below to request an advance',
          );
        }

        // Summary at top
        final totalRequested = advances.fold(0.0, (s, a) => s + a.amount);
        final totalRemaining = advances.fold(0.0, (s, a) => s + a.remainingAmount);
        final pending = advances.where((a) => a.status == 'pending').length;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.surface,
              child: Row(
                children: [
                  Expanded(child: SummaryCard(title: 'Total Requested', value: '₹${_formatNumber(totalRequested)}', color: AppColors.primary, icon: Icons.arrow_upward_rounded)),
                  const SizedBox(width: 10),
                  Expanded(child: SummaryCard(title: 'Remaining', value: '₹${_formatNumber(totalRemaining)}', color: AppColors.warning, icon: Icons.pending_rounded)),
                  const SizedBox(width: 10),
                  Expanded(child: SummaryCard(title: 'Pending Approval', value: '$pending', color: AppColors.error, icon: Icons.hourglass_bottom_rounded)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: advances.length,
                itemBuilder: (_, i) {
                  final adv = advances[i];
                  return AdvanceCard(
                    advance: adv,
                    onTap: () => _showAdvanceDetail(adv),
                    onStatusUpdate: (status) => _updateAdvanceStatus(adv.id!, status),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Components Tab (Deductions + Earnings sub-tabs) ───────────────

  Widget _buildDeductionsTab() {
    return Column(
      children: [
        // Inner tab bar
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: _componentsTabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 2.5,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            tabs: const [
              Tab(icon: Icon(Icons.trending_down_rounded, size: 16), text: 'Deductions'),
              Tab(icon: Icon(Icons.trending_up_rounded, size: 16), text: 'Earnings'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _componentsTabController,
            children: [
              _buildDeductionsSubTab(),
              _buildEarningsSubTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeductionsSubTab() {
    final state = ref.watch(deductionNotifierProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => Center(child: Text('Error: $e')),
      data: (deductions) {
        if (deductions.isEmpty) {
          return _emptyState(
            icon: Icons.remove_circle_outline_rounded,
            title: 'No deductions configured',
            subtitle: 'Add salary deductions like PF, TDS, ESI',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: deductions.length,
          itemBuilder: (_, i) {
            final ded = deductions[i];
            return DeductionCard(
              deduction: ded,
              onEdit:   () => EditDeductionDialog.show(context, deduction: ded,
                  onSuccess: () => ref.read(deductionNotifierProvider.notifier).loadDeductions()),
              onToggle: () => _toggleDeduction(ded),
              onDelete: () => _deleteDeduction(ded),
            );
          },
        );
      },
    );
  }

  Widget _buildEarningsSubTab() {
    final state = ref.watch(earningNotifierProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => Center(child: Text('Error: $e')),
      data: (earnings) {
        if (earnings.isEmpty) {
          return _emptyState(
            icon: Icons.trending_up_rounded,
            title: 'No earning components configured',
            subtitle: 'Add earnings like HRA, Allowances, Bonus',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: earnings.length,
          itemBuilder: (_, i) {
            final earn = earnings[i];
            return EarningCard(
              earning:  earn,
              onEdit:   () => EditEarningDialog.show(context, earning: earn,
                  onSuccess: () => ref.read(earningNotifierProvider.notifier).loadEarnings()),
              onToggle: () => _toggleEarning(earn),
              onDelete: () => _deleteEarning(earn),
            );
          },
        );
      },
    );
  }

  // ── Periods Tab ───────────────────────────────────────────────────

  Widget _buildPeriodsTab() {
    final periodsAsync = ref.watch(periodsProvider);
    return periodsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => Center(child: Text('Error: $e')),
      data: (periods) {
        if (periods.isEmpty) {
          return _emptyState(
            icon: Icons.calendar_month_rounded,
            title: 'No salary periods yet',
            subtitle: 'Create a period to start generating salary slips',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: periods.length,
          itemBuilder: (_, i) {
            final p = periods[i];
            return PeriodCard(
              period:      p,
              isSelected:  _selectedPeriod?.id == p.id,
              onTap:       () => _onPeriodChanged(p),
              onToggleLock: () => _showLockPeriodDialog(p),
            );
          },
        );
      },
    );
  }

  // ── Empty state helper ────────────────────────────────────────────

  Widget _emptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: AppColors.primary.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.black87)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  // ── Dialog launchers ──────────────────────────────────────────────

  void _showSlipDetail(SalarySlip slip) {
    showDialog(context: context, builder: (_) => SalarySlipDetailDialog(slip: slip));
  }

  void _showSlipEdit(SalarySlip slip) {
    showDialog(
      context: context,
      builder: (_) => SalarySlipEditDialog(slip: slip),
    ).then((_) {
        ref.read(salaryNotifierProvider.notifier).loadSlips(
          periodId: _selectedPeriod?.id,
          employeeId: _selectedEmployee?.id,
          departmentId: _selectedDepartment?.id,
          status: _selectedStatus == 'all' ? null : _selectedStatus,
        );
      });
  }

  void _showPaymentDialog(SalarySlip slip) {
    showDialog(
      context: context,
      builder: (_) => SalarySlipPaymentDialog(slip: slip),
    ).then((_) {
        ref.read(salaryNotifierProvider.notifier).loadSlips(
          periodId: _selectedPeriod?.id,
          employeeId: _selectedEmployee?.id,
          departmentId: _selectedDepartment?.id,
          status: _selectedStatus == 'all' ? null : _selectedStatus,
        );
      });
  }

  void _showDeleteDialog(SalarySlip slip) {
    showDialog(
      context: context,
      builder: (_) => SalarySlipDeleteDialog(slip: slip),
    ).then((_) {
        ref.read(salaryNotifierProvider.notifier).loadSlips(
          periodId: _selectedPeriod?.id,
          employeeId: _selectedEmployee?.id,
          departmentId: _selectedDepartment?.id,
          status: _selectedStatus == 'all' ? null : _selectedStatus,
        );
      });
  }

  void _showAdvanceDetail(SalaryAdvance advance) {
    showDialog(context: context, builder: (_) => AdvanceDetailDialog(advance: advance));
  }

  void _showAdvanceRequestDialog() {
    AdvanceRequestDialog.show(
      context,
      employees: _employees,
      onSuccess: () => ref.read(advanceNotifierProvider.notifier).loadAdvances(),
    );
  }

  void _showAddDeductionDialog() {
    AddDeductionDialog.show(context,
        onSuccess: () => ref.read(deductionNotifierProvider.notifier).loadDeductions());
  }

  void _showAddEarningDialog() {
    AddEarningDialog.show(context,
        onSuccess: () => ref.read(earningNotifierProvider.notifier).loadEarnings());
  }

  void _showCreatePeriodDialog() {
    CreatePeriodDialog.show(context, onSuccess: () {
      ref.invalidate(periodsProvider);
    });
  }

  void _showGenerateIndividualDialog() {
    if (_selectedPeriod == null) { _showError('Select a period first'); return; }
    EmployeeSalary? selected;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text('Generate Salary Slip', style: TextStyle(fontWeight: FontWeight.w700)),
          content: DropdownButtonFormField<EmployeeSalary>(
            value: selected,
            decoration: const InputDecoration(
              labelText: 'Select Employee',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline),
            ),
            items: _employees.map((e) => DropdownMenuItem(
              value: e,
              child: Text('${e.fullName} (${e.employeeCode})'),
            )).toList(),
            onChanged: (v) => setS(() => selected = v),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: selected == null ? null : () async {
                try {
                  await ref.read(salaryNotifierProvider.notifier)
                    .generateSlip(selected!.id, _selectedPeriod!.id!);
                  if (ctx.mounted) Navigator.pop(ctx);
                  ref.read(salaryNotifierProvider.notifier).loadSlips(
                    periodId: _selectedPeriod?.id,
                    employeeId: _selectedEmployee?.id,
                    departmentId: _selectedDepartment?.id,
                    status: _selectedStatus == 'all' ? null : _selectedStatus,
                  );
                  _showSuccess('Salary slip generated');
                } catch (e) { _showError('Error: $e'); }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text('Generate'),
            ),
          ],
        ),
      ),
    );
  }

  void _showGenerateBulkDialog(SalaryPeriod period) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome, color: AppColors.accent, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Bulk Generate — ${period.monthName}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.warning, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This will generate salary slips for all active employees based on their attendance records.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                final result = await ref.read(salaryNotifierProvider.notifier).bulkGenerate(period.id!);
                if (ctx.mounted) Navigator.pop(ctx);
                final ok = result['success'] is List
                    ? (result['success'] as List).length
                    : (result['success'] ?? 0);

                final fail = result['failed'] is List
                    ? (result['failed'] as List).length
                    : (result['failed'] ?? 0);
                _showSuccess('Generated: $ok slips${fail > 0 ? ', Failed: $fail' : ''}');
                ref.read(salaryNotifierProvider.notifier).loadSlips(
                  periodId: _selectedPeriod?.id,
                  employeeId: _selectedEmployee?.id,
                  departmentId: _selectedDepartment?.id,
                  status: _selectedStatus == 'all' ? null : _selectedStatus,
                );
              } catch (e) { _showError('Error: $e'); }
            },
            icon: const Icon(Icons.auto_awesome, size: 16),
            label: const Text('Generate All'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  void _showLockPeriodDialog(SalaryPeriod period) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(period.isLocked ? 'Unlock Period' : 'Lock Period',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(period.isLocked
            ? 'Unlock ${period.monthName} to allow editing?'
            : 'Lock ${period.monthName} to prevent changes?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final repo = ref.read(salaryRepositoryProvider);
                await repo.lockPeriod(period.id!, !period.isLocked);
                ref.invalidate(periodsProvider);
                if (ctx.mounted) Navigator.pop(ctx);
                _showSuccess(period.isLocked ? 'Period unlocked' : 'Period locked');
              } catch (e) { _showError('Error: $e'); }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: period.isLocked ? AppColors.success : AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(period.isLocked ? 'Unlock' : 'Lock'),
          ),
        ],
      ),
    );
  }

  // ── Action handlers ───────────────────────────────────────────────

  Future<void> _updateAdvanceStatus(int id, String status) async {
    try {
      final repo = ref.read(salaryRepositoryProvider);
      if (status == 'approved') {
        await repo.approveAdvance(id);
      } else {
        await repo.rejectAdvance(id);
      }
      ref.read(advanceNotifierProvider.notifier).loadAdvances();
      _showSuccess('Advance $status',
          color: status == 'approved' ? AppColors.success : AppColors.error);
    } catch (e) { _showError('Error: $e'); }
  }

  Future<void> _toggleDeduction(SalaryDeduction ded) async {
    try {
      final notifier = ref.read(deductionNotifierProvider.notifier);
      await notifier.updateDeduction(
        ded.id!,
        name: ded.name,
        type: ded.type,
        description: ded.description,
        calculationType: ded.calculationType,
        value: ded.value,
        isActive: !(ded.isActive ?? true),
      );
    } catch (e) { _showError('Error: $e'); }
  }

  Future<void> _deleteDeduction(SalaryDeduction ded) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Deduction'),
        content: Text('Delete "${ded.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final notifier = ref.read(deductionNotifierProvider.notifier);
      await notifier.deleteDeduction(ded.id!);
    } catch (e) { _showError('Error: $e'); }
  }

  Future<void> _toggleEarning(SalaryEarning earn) async {
    try {
      await ref.read(earningNotifierProvider.notifier).updateEarning(
        earn.id!,
        name: earn.name,
        type: earn.type,
        description: earn.description,
        calculationType: earn.calculationType,
        value: earn.value,
        isActive: !(earn.isActive ?? true),
      );
    } catch (e) { _showError('Error: $e'); }
  }

  Future<void> _deleteEarning(SalaryEarning earn) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Earning'),
        content: Text('Delete "${earn.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(earningNotifierProvider.notifier).deleteEarning(earn.id!);
    } catch (e) { _showError('Error: $e'); }
  }
}