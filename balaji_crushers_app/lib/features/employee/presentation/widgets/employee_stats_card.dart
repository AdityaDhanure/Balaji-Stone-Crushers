import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/employee_provider.dart';

class EmployeeStatsCard extends StatelessWidget {
  final EmployeeStats? stats;
  final bool isSmallScreen;

  const EmployeeStatsCard({
    super.key,
    required this.stats,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    if (stats == null) {
      return Container(
        height: isSmallScreen ? 120 : 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppColors.surface,
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final currencyFormat = NumberFormat('#,##,###');

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A5F), Color(0xFF2E5D9F), Color(0xFF1a4080)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decorative circles
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            right: 60,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: const Icon(Icons.people_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Workforce Overview',
                          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${stats?.activeCount ?? 0} active employees',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 16 : 20),
                isSmallScreen
                    ? Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _StatsChip(label: 'Total', value: '${stats?.totalEmployees ?? 0}', icon: Icons.groups_rounded)),
                              const SizedBox(width: 10),
                              Expanded(child: _StatsChip(label: 'Permanent', value: '${stats?.permanentCount ?? 0}', icon: Icons.badge_rounded)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(child: _StatsChip(label: 'Contract', value: '${stats?.contractCount ?? 0}', icon: Icons.assignment_ind_rounded)),
                              const SizedBox(width: 10),
                              Expanded(child: _StatsChip(label: 'Monthly Salary', value: '₹${currencyFormat.format(stats?.totalSalary ?? 0.0)}', icon: Icons.account_balance_wallet_rounded, isHighlight: true)),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: _StatsChip(label: 'Total', value: '${stats?.totalEmployees ?? 0}', icon: Icons.groups_rounded)),
                          const SizedBox(width: 12),
                          Expanded(child: _StatsChip(label: 'Permanent', value: '${stats?.permanentCount ?? 0}', icon: Icons.badge_rounded)),
                          const SizedBox(width: 12),
                          Expanded(child: _StatsChip(label: 'Contract', value: '${stats?.contractCount ?? 0}', icon: Icons.assignment_ind_rounded)),
                          const SizedBox(width: 12),
                          Expanded(child: _StatsChip(label: 'Monthly Salary', value: '₹${currencyFormat.format(stats?.totalSalary ?? 0.0)}', icon: Icons.account_balance_wallet_rounded, isHighlight: true)),
                        ],
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isHighlight;

  const _StatsChip({
    required this.label,
    required this.value,
    required this.icon,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isHighlight
            ? const Color(0xFFE67E22).withValues(alpha: 0.25)
            : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlight
              ? const Color(0xFFE67E22).withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: isHighlight ? const Color(0xFFF39C12) : Colors.white70, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: isHighlight ? const Color(0xFFF39C12) : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}