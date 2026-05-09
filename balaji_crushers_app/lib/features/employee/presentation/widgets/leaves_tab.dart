import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/ist_date_utils.dart';
import '../providers/employee_provider.dart';

class LeavesTab extends ConsumerWidget {
  final bool isSmallScreen;
  final Function(int) onApproveLeave;
  final Function(int) onRejectLeave;

  const LeavesTab({
    super.key,
    required this.isSmallScreen,
    required this.onApproveLeave,
    required this.onRejectLeave,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(employeeProvider);

    if (state.pendingLeaves.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 12, bottom: 16),
      itemCount: state.pendingLeaves.length,
      itemBuilder: (context, index) {
        final leave = state.pendingLeaves[index];
        return _LeaveCard(
          leave: leave,
          onApprove: () => onApproveLeave(leave.id),
          onReject: () => onRejectLeave(leave.id),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline_rounded, size: 48, color: AppColors.success),
          ),
          const SizedBox(height: 16),
          const Text('All caught up!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          const Text(
            'No pending leave requests',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _LeaveCard extends StatelessWidget {
  final PendingLeave leave;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _LeaveCard({required this.leave, required this.onApprove, required this.onReject});

  @override
  Widget build(BuildContext context) {
    final startDate = appParseIstDate(leave.startDate);
    final endDate = appParseIstDate(leave.endDate);
    final Color leaveColor = _getLeaveColor(leave.leaveType);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // Top accent line
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: leaveColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Avatar + Name + Leave type badge
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: leaveColor.withValues(alpha: 0.12),
                      child: Text(
                        leave.employeeName[0].toUpperCase(),
                        style: TextStyle(color: leaveColor, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(leave.employeeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          if (leave.departmentName != null && leave.departmentName!.isNotEmpty)
                            Text(leave.departmentName!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: leaveColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: leaveColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(leave.leaveTypeDisplay, style: TextStyle(fontSize: 11, color: leaveColor, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Date info
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.date_range_rounded, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        startDate != null && endDate != null
                            ? '${DateFormat('dd MMM').format(startDate)} → ${DateFormat('dd MMM yyyy').format(endDate)}'
                            : '${leave.startDate} → ${leave.endDate}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${leave.totalDays} day${leave.totalDays > 1 ? "s" : ""}',
                          style: const TextStyle(fontSize: 11, color: AppColors.info, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                if (leave.reason != null && leave.reason!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.notes_rounded, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          leave.reason!,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: 'Reject',
                        icon: Icons.close_rounded,
                        color: AppColors.error,
                        filled: false,
                        onTap: onReject,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionButton(
                        label: 'Approve',
                        icon: Icons.check_rounded,
                        color: AppColors.success,
                        filled: true,
                        onTap: onApprove,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getLeaveColor(String type) {
    switch (type) {
      case 'sick':
        return AppColors.error;
      case 'casual':
        return AppColors.info;
      case 'earned':
        return AppColors.success;
      case 'unpaid':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: filled ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: filled ? Colors.white : color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: filled ? Colors.white : color),
            ),
          ],
        ),
      ),
    );
  }
}
