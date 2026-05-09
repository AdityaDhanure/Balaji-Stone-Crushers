import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A compact month/year navigator widget.
/// Used inside tabs when a more compact date navigation is needed
/// compared to the full ReportPeriodSelector.
class MonthSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onChanged;
  final bool yearOnly;

  const MonthSelector({
    super.key,
    required this.selectedDate,
    required this.onChanged,
    this.yearOnly = false,
  });

  String get _label => yearOnly
      ? selectedDate.year.toString()
      : DateFormat('MMMM yyyy').format(selectedDate);

  void _prev() {
    if (yearOnly) {
      onChanged(DateTime(selectedDate.year - 1));
    } else {
      onChanged(DateTime(selectedDate.year, selectedDate.month - 1));
    }
  }

  void _next() {
    if (yearOnly) {
      onChanged(DateTime(selectedDate.year + 1));
    } else {
      onChanged(DateTime(selectedDate.year, selectedDate.month + 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Prev button ──────────────────────────
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            onPressed: _prev,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),

          // ── Label ────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              _label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ),

          // ── Next button ──────────────────────────
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            onPressed: _next,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }
}