import 'package:flutter/material.dart';

class QuickMarkButton extends StatelessWidget {
  final String label;
  final String status;
  final bool enabled;
  final Color color;
  final VoidCallback? onPressed;

  const QuickMarkButton({
    super.key,
    required this.label,
    required this.status,
    required this.enabled,
    required this.color,
    this.onPressed,
  });

  IconData get _icon {
    switch (status) {
      case 'present':  return Icons.check_circle_rounded;
      case 'absent':   return Icons.cancel_rounded;
      case 'half_day': return Icons.brightness_5_rounded;
      case 'leave':    return Icons.event_available_rounded;
      default:         return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: enabled ? 1.0 : 0.45,
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: enabled ? color : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _icon,
                  size: 15,
                  color: enabled ? Colors.white : Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: enabled ? Colors.white : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}