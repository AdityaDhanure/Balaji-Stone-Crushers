import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:balaji_crushers_app/core/constants/app_colors.dart';
import 'package:balaji_crushers_app/features/expense/data/models/expense_models.dart';
import 'package:balaji_crushers_app/features/expense/presentation/providers/expense_provider.dart';
import 'package:balaji_crushers_app/features/expense/presentation/widgets/expense_item_card.dart';

/// Builds the expense list for a given [type] and date range.
class ExpenseListView extends ConsumerWidget {
  final String? type;
  final DateTime startDate;
  final DateTime endDate;
  final void Function(UnifiedExpense) onTap;
  final void Function(UnifiedExpense) onEdit;
  final void Function(UnifiedExpense) onDelete;

  const ExpenseListView({
    super.key,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(unifiedExpensesProvider((
      startDate: startDate,
      endDate: endDate,
      type: type,
    )));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 40),
              ),
              const SizedBox(height: 14),
              const Text('Failed to load expenses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 6),
              Text('$e', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
      ),
      data: (items) {
        if (items.isEmpty) return _EmptyState(type: type);
        final sorted = [...items]..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: sorted.length,
          itemBuilder: (_, i) => ExpenseItemCard(
            expense: sorted[i],
            onTap: () => onTap(sorted[i]),
            onEdit: sorted[i].source == 'manual' ? () => onEdit(sorted[i]) : null,
            onDelete: sorted[i].source == 'manual' ? () => onDelete(sorted[i]) : null,
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String? type;
  const _EmptyState({this.type});

  static const _typeLabels = {
    'manual': 'manual expenses',
    'diesel': 'diesel expenses',
    'blast': 'blast expenses',
    'royalty': 'royalty expenses',
    'maintenance': 'maintenance expenses',
    'salary': 'salary expenses',
    'advance': 'advance expenses',
    'production': 'production expenses',
  };

  static const _typeIcons = {
    'manual': Icons.receipt_long_rounded,
    'diesel': Icons.local_gas_station_rounded,
    'blast': Icons.flash_on_rounded,
    'royalty': Icons.account_balance_rounded,
    'maintenance': Icons.build_rounded,
    'salary': Icons.people_rounded,
    'advance': Icons.account_balance_wallet_rounded,
    'production': Icons.factory_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final label = type != null ? _typeLabels[type] ?? '$type expenses' : 'expenses';
    final icon = type != null ? _typeIcons[type] ?? Icons.receipt_long_rounded : Icons.receipt_long_rounded;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 44, color: AppColors.primary.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 16),
          Text('No $label this month', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          const Text('Expenses will appear here once recorded', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
