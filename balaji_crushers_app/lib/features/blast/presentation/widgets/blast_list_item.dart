import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/ist_date_utils.dart';

class BlastListItem extends StatelessWidget {
  final dynamic blast;
  final bool isSmallScreen;
  final VoidCallback onTap;

  const BlastListItem({
    super.key,
    required this.blast,
    required this.isSmallScreen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final isActive = blast['status'] == 'active';

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isActive ? AppColors.accent.withValues(alpha: 0.5) : AppColors.border),
          ),
          child: Row(
            children: [
              _buildIcon(isActive),
              SizedBox(width: isSmallScreen ? 12 : 16),
              Expanded(child: _buildInfo(dateFormat, isActive)),
              _buildStats(),
              SizedBox(width: isSmallScreen ? 4 : 8),
              Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: isSmallScreen ? 20 : 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(bool isActive) {
    return Container(
      width: isSmallScreen ? 40 : 50,
      height: isSmallScreen ? 40 : 50,
      decoration: BoxDecoration(
        color: isActive ? AppColors.accent.withValues(alpha: 0.1) : AppColors.textSecondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.bolt_rounded, color: isActive ? AppColors.accent : AppColors.textSecondary, size: isSmallScreen ? 20 : 24),
    );
  }

  Widget _buildInfo(DateFormat dateFormat, bool isActive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Blast #${blast['blast_number']}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmallScreen ? 13 : 15)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isActive ? AppColors.success.withValues(alpha: 0.1) : AppColors.textSecondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                blast['blast_type'].toString().toUpperCase(),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? AppColors.success : AppColors.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${dateFormat.format(appParseIstDate(blast['blast_date']) ?? appTodayIstDate())} • ${blast['feet']} feet',
          style: TextStyle(color: AppColors.textSecondary, fontSize: isSmallScreen ? 11 : 13),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('${blast['total_trips'] ?? 0} trips', style: TextStyle(fontWeight: FontWeight.w600, fontSize: isSmallScreen ? 12 : 14)),
        Text(
          '₹${NumberFormat.compact().format(double.tryParse(blast['total_expenses']?.toString() ?? '0') ?? 0)}',
          style: TextStyle(color: AppColors.textSecondary, fontSize: isSmallScreen ? 11 : 12),
        ),
      ],
    );
  }
}

class BlastEmptyState extends StatelessWidget {
  const BlastEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.bolt_outlined, size: 48, color: AppColors.textSecondary),
            SizedBox(height: 12),
            Text('No blasts yet', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
