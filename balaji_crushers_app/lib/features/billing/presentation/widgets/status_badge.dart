import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class BillingStatusBadge extends StatelessWidget {
  final String status;
  final bool compact;

  const BillingStatusBadge({super.key, required this.status, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final (Color color, String text, IconData icon) = _resolve(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!compact) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: compact ? 9 : 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static (Color, String, IconData) _resolve(String status) {
    switch (status) {
      case 'paid':
        return (AppColors.success, 'PAID', Icons.check_circle_rounded);
      case 'pending':
        return (AppColors.warning, 'PENDING', Icons.schedule_rounded);
      case 'partial':
        return (AppColors.info, 'PARTIAL', Icons.pie_chart_rounded);
      case 'cancelled':
        return (AppColors.error, 'CANCELLED', Icons.cancel_rounded);
      default:
        return (AppColors.textSecondary, 'DRAFT', Icons.edit_document);
    }
  }
}

// Keep backward-compatible name
class StatusBadge extends BillingStatusBadge {
  const StatusBadge({super.key, required super.status});
}