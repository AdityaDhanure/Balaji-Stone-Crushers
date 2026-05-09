import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:balaji_crushers_app/core/constants/app_colors.dart';
import 'package:balaji_crushers_app/features/expense/presentation/providers/expense_provider.dart';
import 'package:balaji_crushers_app/features/expense/presentation/widgets/expense_summary_strip.dart';

DateTime _nowIst() =>
    DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));

/// Month navigation bar + summary strip. Self-contained widget.
class ExpenseHeaderWidget extends ConsumerWidget {
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<String?> onTypeSelected;
  final String? selectedType;

  const ExpenseHeaderWidget({
    super.key,
    required this.selectedMonth,
    required this.onMonthChanged,
    required this.onTypeSelected,
    this.selectedType,
  });

  DateTime get _startDate => DateTime(selectedMonth.year, selectedMonth.month, 1);
  DateTime get _endDate {
    final lastDay = DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
    return DateTime(selectedMonth.year, selectedMonth.month, lastDay, 23, 59, 59);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(expenseSummaryProvider((
      startDate: _startDate,
      endDate: _endDate,
    )));

    return Container(
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MonthNavBar(selectedMonth: selectedMonth, onMonthChanged: onMonthChanged),
          const SizedBox(height: 6),
          summaryAsync.when(
            data: (summary) => ExpenseSummaryStrip(
              summary: summary,
              selectedType: selectedType,
              onTypeSelected: onTypeSelected,
            ),
            loading: () => const SizedBox(
              height: 90,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                  const SizedBox(width: 8),
                  Text('Failed to load summary', style: const TextStyle(color: AppColors.error, fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _MonthNavBar extends StatelessWidget {
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthChanged;

  const _MonthNavBar({required this.selectedMonth, required this.onMonthChanged});

  @override
  Widget build(BuildContext context) {
    final label = DateFormat('MMMM yyyy').format(selectedMonth);
    final now = _nowIst();
    final isCurrentMonth =
        selectedMonth.year == now.year && selectedMonth.month == now.month;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Expenses', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              Row(
                children: [
                  Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  if (isCurrentMonth) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                      ),
                      child: const Text('Current', style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const Spacer(),
          _NavBtn(icon: Icons.chevron_left_rounded, onTap: () => onMonthChanged(DateTime(selectedMonth.year, selectedMonth.month - 1))),
          const SizedBox(width: 4),
          _NavBtn(icon: Icons.chevron_right_rounded, onTap: () => onMonthChanged(DateTime(selectedMonth.year, selectedMonth.month + 1))),
          const SizedBox(width: 4),
          _NavBtn(
            icon: Icons.calendar_month_rounded,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: selectedMonth,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                initialDatePickerMode: DatePickerMode.year,
              );
              if (date != null) onMonthChanged(DateTime(date.year, date.month));
            },
          ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
    );
  }
}
