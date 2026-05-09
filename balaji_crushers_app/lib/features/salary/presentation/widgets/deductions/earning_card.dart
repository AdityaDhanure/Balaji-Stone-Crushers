import 'package:flutter/material.dart';
import 'package:balaji_crushers_app/core/constants/app_colors.dart';
import 'package:balaji_crushers_app/features/salary/data/models/salary_models.dart';

class EarningCard extends StatelessWidget {
  final SalaryEarning earning;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const EarningCard({
    super.key,
    required this.earning,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'hra':       return const Color(0xFF26A69A); // teal
      case 'allowance': return AppColors.success;
      case 'bonus':     return AppColors.accent;
      default:          return AppColors.primary;
    }
  }

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'hra':       return Icons.home_outlined;
      case 'allowance': return Icons.account_balance_wallet_outlined;
      case 'bonus':     return Icons.star_outline_rounded;
      default:          return Icons.add_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isActive = earning.isActive ?? true;
    final typeColor = _typeColor(earning.type);
    final valueLabel = earning.calculationType == 'percentage'
        ? '${earning.value.toStringAsFixed(1)}%'
        : '₹${earning.value.toStringAsFixed(0)}';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive ? Colors.grey.shade200 : Colors.grey.shade100,
        ),
      ),
      color: isActive ? null : Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Type icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isActive
                    ? typeColor.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _typeIcon(earning.type),
                color: isActive ? typeColor : Colors.grey,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),

            // Name & description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        earning.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isActive ? Colors.black87 : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isActive ? typeColor : Colors.grey).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          earning.type.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: isActive ? typeColor : Colors.grey,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    earning.description ?? '${earning.calculationType == 'percentage' ? 'Percentage' : 'Fixed'} earning',
                    style: TextStyle(
                      fontSize: 11,
                      color: isActive ? AppColors.textSecondary : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Value badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: isActive
                    ? LinearGradient(
                        colors: [typeColor, typeColor.withValues(alpha: 0.7)],
                      )
                    : null,
                color: isActive ? null : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                valueLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: isActive ? Colors.white : Colors.grey,
                ),
              ),
            ),
            const SizedBox(width: 4),

            // 3-dot menu
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.grey.shade500, size: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              itemBuilder: (_) => [
                _menuItem('edit', Icons.edit_outlined, 'Edit', Colors.black87),
                _menuItem(
                  'toggle',
                  isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
                  isActive ? 'Disable' : 'Enable',
                  isActive ? AppColors.warning : AppColors.success,
                ),
                _menuItem('delete', Icons.delete_outline, 'Delete', AppColors.error),
              ],
              onSelected: (val) {
                if (val == 'edit')   onEdit();
                if (val == 'toggle') onToggle();
                if (val == 'delete') onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
