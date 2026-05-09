import 'package:flutter/material.dart';
import 'package:balaji_crushers_app/core/constants/app_colors.dart';
import 'package:balaji_crushers_app/features/expense/utils/expense_utils.dart';
import 'package:balaji_crushers_app/features/expense/data/models/expense_models.dart';

/// Horizontal scrollable strip of colored summary tiles.
class ExpenseSummaryStrip extends StatelessWidget {
  final UnifiedExpenseSummary summary;
  final String? selectedType;
  final ValueChanged<String?> onTypeSelected;

  const ExpenseSummaryStrip({
    super.key,
    required this.summary,
    required this.onTypeSelected,
    this.selectedType,
  });

  @override
  Widget build(BuildContext context) {
    final items = _buildItems();
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => items[i],
      ),
    );
  }

  List<Widget> _buildItems() {
    final diesel = summary.dieselPaid + summary.dieselPending;
    final salaries = summary.salariesPaid + summary.salariesPending;

    return [
      _SummaryTile(label: 'Total', amount: summary.total, color: AppColors.primary, icon: Icons.account_balance_wallet_rounded, isSelected: selectedType == null, onTap: () => onTypeSelected(null), hasPending: summary.dieselPending > 0 || summary.salariesPending > 0),
      _SummaryTile(label: 'Manual', amount: summary.manual, color: const Color(0xFF2196F3), icon: Icons.receipt_long_rounded, isSelected: selectedType == 'manual', onTap: () => onTypeSelected('manual')),
      _SummaryTile(label: 'Diesel', amount: diesel, color: const Color(0xFF4CAF50), icon: Icons.local_gas_station_rounded, isSelected: selectedType == 'diesel', onTap: () => onTypeSelected('diesel'), hasPending: summary.dieselPending > 0, pendingAmount: summary.dieselPending),
      _SummaryTile(label: 'Blast', amount: summary.blast, color: const Color(0xFFF44336), icon: Icons.flash_on_rounded, isSelected: selectedType == 'blast', onTap: () => onTypeSelected('blast')),
      _SummaryTile(label: 'Royalty', amount: summary.royalty, color: const Color(0xFF9C27B0), icon: Icons.account_balance_rounded, isSelected: selectedType == 'royalty', onTap: () => onTypeSelected('royalty')),
      _SummaryTile(label: 'Maintenance', amount: summary.maintenance, color: const Color(0xFFFF9800), icon: Icons.build_rounded, isSelected: selectedType == 'maintenance', onTap: () => onTypeSelected('maintenance')),
      _SummaryTile(label: 'Salaries', amount: salaries, color: const Color(0xFF3F51B5), icon: Icons.people_rounded, isSelected: selectedType == 'salary', onTap: () => onTypeSelected('salary'), hasPending: summary.salariesPending > 0, pendingAmount: summary.salariesPending),
      _SummaryTile(label: 'Advances', amount: summary.advances, color: const Color(0xFF009688), icon: Icons.account_balance_wallet_rounded, isSelected: selectedType == 'advance', onTap: () => onTypeSelected('advance')),
      _SummaryTile(label: 'Production', amount: summary.productionCost, color: const Color(0xFF607D8B), icon: Icons.factory_rounded, isSelected: selectedType == 'production', onTap: () => onTypeSelected('production')),
    ];
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool hasPending;
  final double? pendingAmount;

  const _SummaryTile({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.hasPending = false,
    this.pendingAmount,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 108,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? color : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : AppColors.border, width: isSelected ? 1.5 : 1),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withValues(alpha: 0.2) : color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 13, color: isSelected ? Colors.white : color),
                ),
                if (hasPending) ...[
                  const Spacer(),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : AppColors.warning,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatAmount(amount),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : color),
                  overflow: TextOverflow.ellipsis,
                ),
                if (hasPending && pendingAmount != null && pendingAmount! > 0)
                  Text('${formatAmount(pendingAmount!)} due', style: TextStyle(fontSize: 9, color: isSelected ? Colors.white70 : AppColors.warning)),
                Text(label, style: TextStyle(fontSize: 10, color: isSelected ? Colors.white70 : AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
