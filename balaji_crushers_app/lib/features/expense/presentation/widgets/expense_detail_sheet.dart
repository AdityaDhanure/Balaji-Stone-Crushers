import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:balaji_crushers_app/core/constants/app_colors.dart';
import 'package:balaji_crushers_app/features/expense/data/models/expense_models.dart';

/// Full-detail bottom sheet for any expense type.
class ExpenseDetailSheet extends StatelessWidget {
  final UnifiedExpense expense;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ExpenseDetailSheet({
    super.key,
    required this.expense,
    this.onEdit,
    this.onDelete,
  });

  static void show(
    BuildContext context,
    UnifiedExpense expense, {
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExpenseDetailSheet(expense: expense, onEdit: onEdit, onDelete: onDelete),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = expense.sourceColor;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            // Header section with gradient
            _DetailHeader(expense: expense, color: color),
            // Scrollable body
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  // Pending banner
                  if (expense.isPending) _PendingBanner(),
                  // Core details card
                  _DetailCard(
                    title: 'Expense Details',
                    icon: Icons.info_outline_rounded,
                    children: [
                      _DetailRow(icon: Icons.calendar_today_rounded, label: 'Date', value: DateFormat('dd MMMM yyyy').format(expense.expenseDate)),
                      if (expense.reference != null) _DetailRow(icon: Icons.tag_rounded, label: 'Reference', value: expense.reference!),
                      if (expense.vendorName != null && expense.vendorName!.isNotEmpty)
                        _DetailRow(icon: Icons.storefront_rounded, label: 'Vendor / Party', value: expense.vendorName!),
                      if (expense.paymentMode != null && expense.paymentMode!.isNotEmpty)
                        _DetailRow(icon: Icons.payment_rounded, label: 'Payment Mode', value: expense.paymentMode!.toUpperCase()),
                      if (expense.description != null && expense.description!.isNotEmpty)
                        _DetailRow(icon: Icons.notes_rounded, label: 'Description', value: expense.description!),
                    ],
                  ),
                  // Source-specific info
                  if (_sourceFields().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _DetailCard(
                      title: '${expense.sourceDisplay} Details',
                      icon: expense.sourceIcon,
                      accentColor: color,
                      children: _sourceFields(),
                    ),
                  ],
                  // Actions
                  if (onEdit != null || onDelete != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (onEdit != null)
                          Expanded(
                            child: _DetailActionButton(
                              label: 'Edit Expense',
                              icon: Icons.edit_rounded,
                              color: AppColors.info,
                              filled: false,
                              onTap: () {
                                Navigator.pop(context);
                                Future.microtask(() => onEdit!());
                              },
                            ),
                          ),
                        if (onEdit != null && onDelete != null) const SizedBox(width: 10),
                        if (onDelete != null)
                          Expanded(
                            child: _DetailActionButton(
                              label: 'Delete',
                              icon: Icons.delete_outline_rounded,
                              color: AppColors.error,
                              filled: false,
                              onTap: () {
                                Navigator.pop(context);
                                Future.microtask(() => onDelete!());
                              },
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _sourceFields() {
    final sub = expense.subInfo ?? {};
    switch (expense.source) {
      case 'diesel':
        return [
          if (sub['pump'] != null) _DetailRow(icon: Icons.local_gas_station_rounded, label: 'Pump / Supplier', value: sub['pump'] as String),
          if (sub['quantity'] != null) _DetailRow(icon: Icons.opacity_rounded, label: 'Quantity', value: '${sub['quantity']} L'),
          if (sub['rate'] != null) _DetailRow(icon: Icons.currency_rupee_rounded, label: 'Rate per Litre', value: '₹${sub['rate']}'),
        ];
      case 'maintenance':
        return [
          if (sub['equipment_name'] != null) _DetailRow(icon: Icons.construction_rounded, label: 'Equipment', value: sub['equipment_name'] as String),
          if (sub['vehicle_number'] != null) _DetailRow(icon: Icons.directions_car_rounded, label: 'Vehicle', value: sub['vehicle_number'] as String),
          if (sub['maintenance_type'] != null) _DetailRow(icon: Icons.build_rounded, label: 'Type', value: sub['maintenance_type'] as String),
        ];
      case 'salary':
        return [
          if (sub['employee_code'] != null) _DetailRow(icon: Icons.badge_outlined, label: 'Employee Code', value: sub['employee_code'] as String),
          if (sub['department'] != null) _DetailRow(icon: Icons.business_rounded, label: 'Department', value: sub['department'] as String),
          if (sub['month'] != null && sub['year'] != null) _DetailRow(icon: Icons.event_note_rounded, label: 'Period', value: '${_monthName(sub['month'])} ${sub['year']}'),
        ];
      case 'advance':
        return [
          if (sub['employee_code'] != null) _DetailRow(icon: Icons.badge_outlined, label: 'Employee Code', value: sub['employee_code'] as String),
          if (sub['remaining_amount'] != null) _DetailRow(icon: Icons.account_balance_wallet_rounded, label: 'Remaining', value: '₹${(sub['remaining_amount'] as num).toStringAsFixed(0)}'),
        ];
      case 'production':
        return [
          if (sub['product_name'] != null) _DetailRow(icon: Icons.inventory_rounded, label: 'Product', value: sub['product_name'] as String),
          if (sub['quantity_tons'] != null) _DetailRow(icon: Icons.scale_rounded, label: 'Quantity', value: '${sub['quantity_tons']} tons'),
        ];
      case 'blast':
      case 'royalty':
        return [
          if (sub['blast_id'] != null) _DetailRow(icon: Icons.tag_rounded, label: 'Blast ID', value: '#${sub['blast_id']}'),
        ];
      default:
        return [];
    }
  }

  String _monthName(dynamic m) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final idx = (m as num).toInt() - 1;
    return idx >= 0 && idx < 12 ? months[idx] : m.toString();
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _DetailHeader extends StatelessWidget {
  final UnifiedExpense expense;
  final Color color;
  const _DetailHeader({required this.expense, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(expense.sourceIcon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(expense.categoryName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(5), border: Border.all(color: color.withValues(alpha: 0.25))),
                      child: Text(expense.sourceDisplay, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                    ),
                    if (expense.reference != null) ...[
                      const SizedBox(width: 6),
                      Text('• ${expense.reference}', style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.7))),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${NumberFormat('#,##,###').format(expense.amount.toInt())}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: expense.isPending ? AppColors.warning : color),
              ),
              Text(expense.isPending ? 'Pending' : 'Paid', style: TextStyle(fontSize: 11, color: expense.isPending ? AppColors.warning : AppColors.success, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Pending Banner ────────────────────────────────────────────────────────────

class _PendingBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 16),
          SizedBox(width: 8),
          Text('Payment Pending', style: TextStyle(color: AppColors.warning, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Detail Card ──────────────────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? accentColor;
  final List<Widget> children;

  const _DetailCard({required this.title, required this.icon, required this.children, this.accentColor});

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primary;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, size: 14, color: color),
                ),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

// ─── Detail Row ───────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

// ─── Action Button ────────────────────────────────────────────────────────────

class _DetailActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _DetailActionButton({required this.label, required this.icon, required this.color, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: filled ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: filled ? Colors.white : color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: filled ? Colors.white : color)),
          ],
        ),
      ),
    );
  }
}
