import 'package:flutter/material.dart';
import 'package:balaji_crushers_app/core/constants/app_colors.dart';
import 'package:balaji_crushers_app/features/salary/data/models/salary_models.dart';
import 'package:balaji_crushers_app/features/salary/presentation/widgets/common/info_chip.dart';

class SalarySlipCard extends StatelessWidget {
  final SalarySlip slip;
  final VoidCallback onPay;
  final VoidCallback onView;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const SalarySlipCard({
    super.key,
    required this.slip,
    required this.onPay,
    required this.onView,
    required this.onDelete,
    required this.onEdit,
  });

  Color get _statusColor {
    switch (slip.status) {
      case 'paid':    return AppColors.success;
      case 'pending': return AppColors.warning;
      case 'draft':   return AppColors.textSecondary;
      default:        return AppColors.info;
    }
  }

  IconData get _statusIcon {
    switch (slip.status) {
      case 'paid':    return Icons.check_circle_rounded;
      case 'pending': return Icons.hourglass_bottom_rounded;
      case 'draft':   return Icons.drafts_rounded;
      default:        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = slip.employeeName.isNotEmpty
        ? slip.employeeName.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : '?';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // ── Top accent bar ──────────────────────────
          Container(
            height: 4,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              gradient: LinearGradient(
                colors: [_statusColor, _statusColor.withValues(alpha: 0.4)],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header Row ──────────────────────────
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Name & info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            slip.employeeName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (slip.employeeCode != null) ...[
                                Icon(Icons.badge_outlined, size: 11, color: AppColors.textSecondary),
                                const SizedBox(width: 3),
                                Text(
                                  slip.employeeCode!,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                                const SizedBox(width: 8),
                              ],
                              if (slip.departmentName != null) ...[
                                Icon(Icons.business_outlined, size: 11, color: AppColors.textSecondary),
                                const SizedBox(width: 3),
                                Text(
                                  slip.departmentName!,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_statusIcon, size: 12, color: _statusColor),
                          const SizedBox(width: 4),
                          Text(
                            slip.status.toUpperCase(),
                            style: TextStyle(
                              color: _statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                Divider(color: Colors.grey.shade100, height: 1),
                const SizedBox(height: 14),

                // ── Stats Row ──────────────────────────
                Row(
                  children: [
                    // Attendance chips
                    InfoChip(
                      label: 'Present',
                      value: '${slip.presentDays ?? 0}d',
                      color: AppColors.success,
                      icon: Icons.check_circle_outline,
                    ),
                    if ((slip.leaveDays ?? 0) > 0) ...[
                      const SizedBox(width: 6),
                      InfoChip(
                        label: 'Leave',
                        value: '${slip.leaveDays}d',
                        color: AppColors.info,
                        icon: Icons.event_available_outlined,
                      ),
                    ],
                    if ((slip.halfDays ?? 0) > 0) ...[
                      const SizedBox(width: 6),
                      InfoChip(
                        label: 'Half Day',
                        value: '${slip.halfDays}',
                        color: AppColors.warning,
                        icon: Icons.brightness_5_outlined,
                      ),
                    ],
                    if ((slip.absentDays ?? 0) > 0) ...[
                      const SizedBox(width: 6),
                      InfoChip(
                        label: 'Absent',
                        value: '${slip.absentDays}d',
                        color: AppColors.error,
                        icon: Icons.cancel_outlined,
                      ),
                    ],
                    const SizedBox(width: 6),
                    InfoChip(
                      label: 'Earnings',
                      value: '₹${_compact(slip.totalEarnings)}',
                      color: AppColors.primaryLight,
                    ),

                    const Spacer(),

                    // Net salary highlight box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'NET SALARY',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Text(
                            '₹${slip.netSalary.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                Divider(color: Colors.grey.shade100, height: 1),
                const SizedBox(height: 8),

                // ── Actions ──────────────────────────
                Row(
                  children: [
                    // Deduction info
                    if (slip.totalDeductions > 0)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          'Deductions: ₹${slip.totalDeductions.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),

                    const Spacer(),

                    _ActionBtn(
                      label: 'View',
                      icon: Icons.visibility_outlined,
                      onPressed: onView,
                      color: AppColors.info,
                    ),
                    const SizedBox(width: 6),
                    _ActionBtn(
                      label: 'Edit',
                      icon: Icons.edit_outlined,
                      onPressed: onEdit,
                      color: AppColors.primary,
                    ),
                    if (slip.status != 'paid') ...[
                      const SizedBox(width: 6),
                      _ActionBtn(
                        label: 'Pay',
                        icon: Icons.payment_rounded,
                        onPressed: onPay,
                        color: AppColors.success,
                        filled: true,
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        color: AppColors.error,
                        onPressed: onDelete,
                        tooltip: 'Delete',
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.error.withValues(alpha: 0.08),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.all(6),
                          minimumSize: const Size(32, 32),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _compact(double val) {
    if (val >= 100000) return '${(val / 100000).toStringAsFixed(1)}L';
    if (val >= 1000) return '${(val / 1000).toStringAsFixed(1)}K';
    return val.toStringAsFixed(0);
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  final bool filled;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.color,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 15),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 15),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}