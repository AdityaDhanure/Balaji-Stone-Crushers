import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class MaintenanceStatusBadge extends StatelessWidget {
  final String status;
  final bool compact;

  const MaintenanceStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final (Color color, String text, IconData icon) = _resolve(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 3 : 4,
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
      case 'completed':
        return (AppColors.success, 'DONE', Icons.check_circle_rounded);
      case 'pending':
        return (AppColors.warning, 'PENDING', Icons.schedule_rounded);
      case 'in_progress':
        return (AppColors.info, 'IN PROGRESS', Icons.autorenew_rounded);
      default:
        return (AppColors.textSecondary, status.toUpperCase(), Icons.info_rounded);
    }
  }
}
