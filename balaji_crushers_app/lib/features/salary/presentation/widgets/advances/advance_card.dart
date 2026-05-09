import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:balaji_crushers_app/core/constants/app_colors.dart';
import 'package:balaji_crushers_app/features/salary/data/models/salary_models.dart';
import 'package:balaji_crushers_app/features/salary/presentation/widgets/common/info_chip.dart';

class AdvanceCard extends StatelessWidget {
  final SalaryAdvance advance;
  final VoidCallback onTap;
  final ValueChanged<String> onStatusUpdate;

  const AdvanceCard({
    super.key,
    required this.advance,
    required this.onTap,
    required this.onStatusUpdate,
  });

  Color _statusColor(String s) {
    switch (s) {
      case 'approved': return AppColors.success;
      case 'pending':  return AppColors.warning;
      case 'rejected': return AppColors.error;
      default:         return AppColors.textSecondary;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'approved': return Icons.check_circle_rounded;
      case 'pending':  return Icons.hourglass_bottom_rounded;
      case 'rejected': return Icons.cancel_rounded;
      default:         return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(advance.status);
    final repaidPct = advance.amount > 0
        ? (advance.totalRepaid / advance.amount).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            // Status accent bar
            Container(
              height: 4,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                color: color,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_statusIcon(advance.status), color: color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              advance.employeeName,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                if (advance.employeeCode != null) ...[
                                  Icon(Icons.badge_outlined, size: 11, color: AppColors.textSecondary),
                                  const SizedBox(width: 3),
                                  Text(
                                    advance.employeeCode!,
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Icon(Icons.calendar_today_outlined, size: 11, color: AppColors.textSecondary),
                                const SizedBox(width: 3),
                                Text(
                                  DateFormat('dd MMM yyyy').format(advance.requestDate),
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_statusIcon(advance.status), size: 12, color: color),
                            const SizedBox(width: 4),
                            Text(
                              advance.status.toUpperCase(),
                              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  Divider(color: Colors.grey.shade100, height: 1),
                  const SizedBox(height: 12),

                  // Amount chips
                  Row(
                    children: [
                      InfoChip(
                        label: 'Requested',
                        value: '₹${advance.amount.toStringAsFixed(0)}',
                        color: AppColors.primary,
                        icon: Icons.arrow_upward_rounded,
                      ),
                      if (advance.totalRepaid > 0) ...[
                        const SizedBox(width: 8),
                        InfoChip(
                          label: 'Repaid',
                          value: '₹${advance.totalRepaid.toStringAsFixed(0)}',
                          color: AppColors.success,
                          icon: Icons.arrow_downward_rounded,
                        ),
                      ],
                      if (advance.remainingAmount > 0) ...[
                        const SizedBox(width: 8),
                        InfoChip(
                          label: 'Remaining',
                          value: '₹${advance.remainingAmount.toStringAsFixed(0)}',
                          color: AppColors.warning,
                          icon: Icons.pending_rounded,
                        ),
                      ],
                    ],
                  ),

                  // Repayment progress bar (if any repaid)
                  if (advance.totalRepaid > 0) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: repaidPct,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation(AppColors.success),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(repaidPct * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Approve / Reject buttons (pending only)
                  if (advance.status == 'pending') ...[
                    const SizedBox(height: 14),
                    Divider(color: Colors.grey.shade100, height: 1),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => onStatusUpdate('rejected'),
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text('Reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => onStatusUpdate('approved'),
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
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
}