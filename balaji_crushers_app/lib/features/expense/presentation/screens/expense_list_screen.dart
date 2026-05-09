import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:balaji_crushers_app/core/constants/app_colors.dart';
import 'package:balaji_crushers_app/features/expense/data/models/expense_models.dart';
import 'package:balaji_crushers_app/features/expense/data/repositories/expense_repository.dart';
import 'package:balaji_crushers_app/features/expense/presentation/providers/expense_provider.dart';
import 'package:balaji_crushers_app/features/expense/presentation/widgets/expense_header_widget.dart';
import 'package:balaji_crushers_app/features/expense/presentation/widgets/expense_list_view.dart';
import 'package:balaji_crushers_app/features/expense/presentation/widgets/expense_detail_sheet.dart';
import 'package:balaji_crushers_app/features/expense/presentation/widgets/add_expense_dialog.dart';
import 'package:balaji_crushers_app/features/expense/presentation/widgets/edit_expense_dialog.dart';

DateTime _nowIst() =>
    DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));

DateTime _currentIstMonth() {
  final now = _nowIst();
  return DateTime(now.year, now.month);
}

// ─── Tab configuration ────────────────────────────────────────────────────────

const _kTabLabels = [
  'All', 'Manual', 'Diesel', 'Blast', 'Royalty',
  'Maintenance', 'Salary', 'Advance', 'Production',
];
const _kTabTypes = <String?>[
  null, 'manual', 'diesel', 'blast', 'royalty',
  'maintenance', 'salary', 'advance', 'production',
];

const _kTabIcons = <IconData>[
  Icons.dashboard_rounded,
  Icons.receipt_long_rounded,
  Icons.local_gas_station_rounded,
  Icons.flash_on_rounded,
  Icons.account_balance_rounded,
  Icons.build_rounded,
  Icons.people_rounded,
  Icons.account_balance_wallet_rounded,
  Icons.factory_rounded,
];

class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  DateTime _selectedMonth = _currentIstMonth();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _kTabLabels.length, vsync: this);
    _tabController.addListener(() {
      setState(() {});
      _refresh(); // 🔥 add this
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DateTime get _startDate => DateTime(_selectedMonth.year, _selectedMonth.month, 1);
  DateTime get _endDate {
    final day = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    return DateTime(_selectedMonth.year, _selectedMonth.month, day, 23, 59, 59);
  }

  String? get _currentType => _kTabTypes[_tabController.index];

  void _jumpToType(String? type) {
    final idx = _kTabTypes.indexOf(type);
    if (idx >= 0) _tabController.animateTo(idx);
  }

  void _onMonthChanged(DateTime m) => setState(() => _selectedMonth = m);

  // ─── Show Add ─────────────────────────────────────────────────────────────

  void _showAdd() {
    final categoriesAsync = ref.read(expenseCategoriesProvider);
    categoriesAsync.whenData((cats) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        AddExpenseDialog.show(context, categories: cats, onSuccess: _refresh);
      });
    });
  }

  // ─── Show Edit ────────────────────────────────────────────────────────────

  Future<void> _showEdit(UnifiedExpense unified) async {
    if (unified.source != 'manual') return;
    final repo = ref.read(expenseRepositoryProvider);
    final expense = await repo.getExpense(unified.id);
    if (!mounted) return;
    final categoriesAsync = ref.read(expenseCategoriesProvider);
    categoriesAsync.whenData((cats) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        EditExpenseDialog.show(context, expense: expense, categories: cats, onSuccess: _refresh);
      });
    });
  }

  // ─── Confirm Delete ───────────────────────────────────────────────────────

  Future<void> _confirmDelete(UnifiedExpense unified) async {
    if (unified.source != 'manual') return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.08), shape: BoxShape.circle),
                child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 28),
              ),
              const SizedBox(height: 14),
              const Text('Delete Expense', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to delete "${unified.categoryName}" of ₹${unified.amount.toStringAsFixed(0)}?\n\nThis action cannot be undone.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirm == true && mounted) {
      await ref.read(expenseRepositoryProvider).deleteExpense(unified.id);
      await Future.delayed(const Duration(milliseconds: 200));
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Expense deleted'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  // ─── Refresh ──────────────────────────────────────────────────────────────

  void _refresh() {
    // refresh only current tab
    ref.invalidate(unifiedExpensesProvider((
      startDate: _startDate,
      endDate: _endDate,
      type: _currentType,
    )));

    // refresh header summary
    ref.invalidate(expenseSummaryProvider((
      startDate: _startDate,
      endDate: _endDate,
    )));
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _ExpenseSliverAppBar(
            tabController: _tabController,
            selectedMonth: _selectedMonth,
            currentType: _currentType,
            onMonthChanged: _onMonthChanged,
            onTypeSelected: _jumpToType,
            innerBoxIsScrolled: innerBoxIsScrolled,
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: _kTabTypes.map((type) => ExpenseListView(
            type: type,
            startDate: _startDate,
            endDate: _endDate,
            onTap: (expense) => ExpenseDetailSheet.show(
              context,
              expense,
              onEdit: expense.source == 'manual' ? () => _showEdit(expense) : null,
              onDelete: expense.source == 'manual' ? () => _confirmDelete(expense) : null,
            ),
            onEdit: _showEdit,
            onDelete: _confirmDelete,
          )).toList(),
        ),
      ),
      floatingActionButton: _AddExpenseFAB(onPressed: _showAdd),
    );
  }
}

// ─── Sliver App Bar ────────────────────────────────────────────────────────────

class _ExpenseSliverAppBar extends StatelessWidget {
  final TabController tabController;
  final DateTime selectedMonth;
  final String? currentType;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<String?> onTypeSelected;
  final bool innerBoxIsScrolled;

  const _ExpenseSliverAppBar({
    required this.tabController,
    required this.selectedMonth,
    required this.currentType,
    required this.onMonthChanged,
    required this.onTypeSelected,
    required this.innerBoxIsScrolled,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      snap: true,
      forceElevated: innerBoxIsScrolled,
      backgroundColor: AppColors.background,
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      surfaceTintColor: Colors.transparent,
      expandedHeight: 215,

      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: ExpenseHeaderWidget(
          selectedMonth: selectedMonth,
          onMonthChanged: onMonthChanged,
          onTypeSelected: onTypeSelected,
          selectedType: currentType,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: AppColors.background,
          child: _ExpenseTabBar(controller: tabController),
        ),
      ),
    );
  }
}

// ─── Tab Bar ──────────────────────────────────────────────────────────────────

class _ExpenseTabBar extends StatelessWidget {
  final TabController controller;
  const _ExpenseTabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.textSecondary,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
      indicator: UnderlineTabIndicator(
        borderSide: const BorderSide(color: AppColors.primary, width: 2.5),
        borderRadius: BorderRadius.circular(2),
        insets: const EdgeInsets.symmetric(horizontal: 8),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: AppColors.border,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      tabs: List.generate(_kTabLabels.length, (i) => Tab(
        height: 42,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_kTabIcons[i], size: 14),
            const SizedBox(width: 5),
            Text(_kTabLabels[i]),
          ],
        ),
      )),
    );
  }
}

// ─── FAB ──────────────────────────────────────────────────────────────────────

class _AddExpenseFAB extends StatelessWidget {
  final VoidCallback onPressed;
  const _AddExpenseFAB({required this.onPressed});

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
                Icon(Icons.add_card_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Add Expense', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
