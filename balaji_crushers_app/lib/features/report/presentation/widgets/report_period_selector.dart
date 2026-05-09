import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:balaji_crushers_app/core/constants/app_colors.dart';
import 'package:balaji_crushers_app/core/utils/ist_date_utils.dart';

enum ReportPeriod { tenDays, monthly, yearly }

class ReportPeriodSelector extends StatelessWidget {
  final ReportPeriod period;
  final DateTime selectedDate;
  final ValueChanged<ReportPeriod> onPeriodChanged;
  final ValueChanged<DateTime> onDateChanged;

  const ReportPeriodSelector({
    super.key,
    required this.period,
    required this.selectedDate,
    required this.onPeriodChanged,
    required this.onDateChanged,
  });

  String get _label {
    switch (period) {
      case ReportPeriod.tenDays:
        return 'Last 10 Days';
      case ReportPeriod.monthly:
        return DateFormat('MMMM yyyy').format(selectedDate);
      case ReportPeriod.yearly:
        return selectedDate.year.toString();
    }
  }

  bool get _showNav =>
      period == ReportPeriod.monthly || period == ReportPeriod.yearly;

  void _prev() {
    if (period == ReportPeriod.monthly) {
      onDateChanged(DateTime(selectedDate.year, selectedDate.month - 1));
    } else {
      onDateChanged(DateTime(selectedDate.year - 1));
    }
  }

  void _next() {
    if (period == ReportPeriod.monthly) {
      onDateChanged(DateTime(selectedDate.year, selectedDate.month + 1));
    } else {
      onDateChanged(DateTime(selectedDate.year + 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          // ── Period type selector ─────────────────────
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                _PeriodChip(
                  label: '10 Days',
                  icon: Icons.calendar_view_week_rounded,
                  isSelected: period == ReportPeriod.tenDays,
                  onTap: () => onPeriodChanged(ReportPeriod.tenDays),
                ),
                _PeriodChip(
                  label: 'Monthly',
                  icon: Icons.calendar_month_rounded,
                  isSelected: period == ReportPeriod.monthly,
                  onTap: () => onPeriodChanged(ReportPeriod.monthly),
                ),
                _PeriodChip(
                  label: 'Yearly',
                  icon: Icons.calendar_today_rounded,
                  isSelected: period == ReportPeriod.yearly,
                  onTap: () => onPeriodChanged(ReportPeriod.yearly),
                ),
              ],
            ),
          ),

          // ── Date navigation ─────────────────────────
          if (_showNav) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _NavButton(
                  icon: Icons.chevron_left_rounded,
                  onTap: _prev,
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    _label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _NavButton(
                  icon: Icons.chevron_right_rounded,
                  onTap: _next,
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color:
                      isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 20, color: AppColors.textSecondary),
      ),
    );
  }
}

/// Computes the date range from a period + anchor date.
({DateTime startDate, DateTime endDate}) periodDateRange(
    ReportPeriod period, DateTime date) {
  final now = appTodayIstDate();
  switch (period) {
    case ReportPeriod.tenDays:
      return (
        startDate: DateTime(now.year, now.month, now.day - 9),
        endDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
      );
    case ReportPeriod.monthly:
      final lastDay = DateTime(date.year, date.month + 1, 0).day;
      return (
        startDate: DateTime(date.year, date.month, 1),
        endDate: DateTime(date.year, date.month, lastDay, 23, 59, 59),
      );
    case ReportPeriod.yearly:
      return (
        startDate: DateTime(date.year, 1, 1),
        endDate: DateTime(date.year, 12, 31, 23, 59, 59),
      );
  }
}
