import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const SummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.13),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 10,
                color: color.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AttendanceSummaryRow extends StatelessWidget {
  final int presentCount;
  final int absentCount;
  final int halfDayCount;
  final int onLeaveCount;

  const AttendanceSummaryRow({
    super.key,
    required this.presentCount,
    required this.absentCount,
    required this.halfDayCount,
    required this.onLeaveCount,
  });

  int get _total => presentCount + absentCount + halfDayCount + onLeaveCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Total attendance bar
        if (_total > 0) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  if (presentCount > 0)
                    Flexible(
                      flex: presentCount,
                      child: Container(color: AppColors.success),
                    ),
                  if (halfDayCount > 0)
                    Flexible(
                      flex: halfDayCount,
                      child: Container(color: AppColors.warning),
                    ),
                  if (onLeaveCount > 0)
                    Flexible(
                      flex: onLeaveCount,
                      child: Container(color: AppColors.info),
                    ),
                  if (absentCount > 0)
                    Flexible(
                      flex: absentCount,
                      child: Container(color: AppColors.error),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                label: 'Present',
                value: '$presentCount',
                icon: Icons.check_circle_rounded,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SummaryCard(
                label: 'Absent',
                value: '$absentCount',
                icon: Icons.cancel_rounded,
                color: AppColors.error,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SummaryCard(
                label: 'Half Day',
                value: '$halfDayCount',
                icon: Icons.brightness_5_rounded,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SummaryCard(
                label: 'On Leave',
                value: '$onLeaveCount',
                icon: Icons.event_available_rounded,
                color: AppColors.info,
              ),
            ),
          ],
        ),
      ],
    );
  }
}