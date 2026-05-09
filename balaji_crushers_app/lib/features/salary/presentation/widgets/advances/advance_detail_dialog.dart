import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:balaji_crushers_app/core/constants/app_colors.dart';
import 'package:balaji_crushers_app/features/salary/data/models/salary_models.dart';
import 'package:balaji_crushers_app/features/salary/presentation/widgets/common/detail_row.dart';

class AdvanceDetailDialog extends StatelessWidget {
  final SalaryAdvance advance;

  const AdvanceDetailDialog({super.key, required this.advance});

  Color get _statusColor {
    switch (advance.status) {
      case 'approved': return AppColors.success;
      case 'pending':  return AppColors.warning;
      case 'rejected': return AppColors.error;
      default:         return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final repaidPct = advance.amount > 0
        ? (advance.totalRepaid / advance.amount).clamp(0.0, 1.0)
        : 0.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_statusColor, _statusColor.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  // Employee avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        advance.employeeName.isNotEmpty
                            ? advance.employeeName.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
                            : '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(advance.employeeName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(advance.employeeCode ?? '',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      advance.status.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount summary boxes
                  Row(
                    children: [
                      _AmountBox(
                        label: 'Requested',
                        value: advance.amount,
                        color: AppColors.primary,
                        icon: Icons.arrow_upward_rounded,
                      ),
                      const SizedBox(width: 10),
                      _AmountBox(
                        label: 'Repaid',
                        value: advance.totalRepaid,
                        color: AppColors.success,
                        icon: Icons.arrow_downward_rounded,
                      ),
                      const SizedBox(width: 10),
                      _AmountBox(
                        label: 'Remaining',
                        value: advance.remainingAmount,
                        color: advance.remainingAmount > 0 ? AppColors.warning : AppColors.success,
                        icon: Icons.pending_rounded,
                      ),
                    ],
                  ),

                  // Repayment progress
                  if (advance.totalRepaid > 0) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: repaidPct,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation(AppColors.success),
                              minHeight: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${(repaidPct * 100).toStringAsFixed(0)}% repaid',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Details
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        DetailRow(
                          'Request Date',
                          DateFormat('dd MMM yyyy').format(advance.requestDate),
                        ),
                        if (advance.repaymentAmount > 0)
                          DetailRow(
                            'Monthly Repayment',
                            '₹${advance.repaymentAmount.toStringAsFixed(2)}',
                          ),
                        if (advance.repaymentStartDate != null)
                          DetailRow(
                            'Repayment Start',
                            DateFormat('dd MMM yyyy').format(advance.repaymentStartDate!),
                          ),
                        if (advance.approvedAt != null) ...[
                          const Divider(height: 12),
                          DetailRow(
                            'Approved On',
                            DateFormat('dd MMM yyyy').format(advance.approvedAt!),
                          ),
                        ],
                        if (advance.reason != null) ...[
                          const Divider(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Reason',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                const SizedBox(height: 4),
                                Text(advance.reason!,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
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

class _AmountBox extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;

  const _AmountBox({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(height: 4),
            Text(
              '₹${value.toStringAsFixed(0)}',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: color),
            ),
            Text(label, style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}