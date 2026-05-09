import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/customer_provider.dart';

class CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;

  const CustomerCard({
    super.key,
    required this.customer,
    required this.onTap,
  });

  static IconData _typeIcon(String type) {
    switch (type) {
      case 'company':    return Icons.business_rounded;
      case 'government': return Icons.account_balance_rounded;
      default:           return Icons.person_rounded;
    }
  }

  static Color _typeColor(String type) {
    switch (type) {
      case 'company':    return AppColors.primary;
      case 'government': return AppColors.accent;
      default:           return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,###');
    final color = _typeColor(customer.customerType);
    final hasBalance = customer.currentBalance != 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Left accent bar
                Container(width: 3, height: 46, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 10),
                // Avatar
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.08)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: customer.customerType == 'individual'
                        ? Text(
                            customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                            style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
                          )
                        : Icon(_typeIcon(customer.customerType), color: color, size: 20),
                  ),
                ),
                const SizedBox(width: 10),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          _Tag(label: customer.customerCode, color: color),
                          const SizedBox(width: 6),
                          _Tag(label: customer.typeDisplay, color: AppColors.textSecondary),
                        ],
                      ),
                      if (customer.phone != null) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.phone_rounded, size: 10, color: AppColors.textSecondary),
                            const SizedBox(width: 3),
                            Text(customer.phone!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Trailing
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasBalance) ...[
                      Text(
                        '₹${fmt.format(customer.currentBalance.abs())}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: customer.currentBalance > 0 ? AppColors.success : AppColors.warning,
                        ),
                      ),
                      Text(
                        customer.currentBalance > 0 ? 'Advance' : 'Due',
                        style: TextStyle(
                          fontSize: 9,
                          color: customer.currentBalance > 0 ? AppColors.success : AppColors.warning,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: customer.isActive
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: customer.isActive
                              ? AppColors.success.withValues(alpha: 0.3)
                              : AppColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        customer.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: customer.isActive ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color)),
    );
  }
}