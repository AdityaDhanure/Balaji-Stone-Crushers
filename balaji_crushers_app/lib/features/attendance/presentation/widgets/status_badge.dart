import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool compact;

  const StatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  Color get _color {
    switch (status) {
      case 'present':  return AppColors.success;
      case 'absent':   return AppColors.error;
      case 'half_day': return AppColors.warning;
      case 'leave':    return AppColors.info;
      case 'holiday':  return AppColors.accent;
      default:         return AppColors.textSecondary;
    }
  }

  IconData get _icon {
    switch (status) {
      case 'present':  return Icons.check_circle_rounded;
      case 'absent':   return Icons.cancel_rounded;
      case 'half_day': return Icons.brightness_5_rounded;
      case 'leave':    return Icons.event_available_rounded;
      case 'holiday':  return Icons.celebration_rounded;
      default:         return Icons.help_rounded;
    }
  }

  String get _label {
    switch (status) {
      case 'half_day': return 'Half Day';
      case 'leave':    return 'On Leave';
      case 'holiday':  return 'Holiday';
      default:         return status[0].toUpperCase() + status.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: compact ? 11 : 13, color: _color),
          const SizedBox(width: 4),
          Text(
            _label,
            style: TextStyle(
              color: _color,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}