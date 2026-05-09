import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/billing_provider.dart';

class BillingStatsCard extends StatelessWidget {
  final InvoiceStats? stats;
  final bool isSmallScreen;

  const BillingStatsCard({
    super.key,
    required this.stats,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,###');
    final s = stats;

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
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            top: -30, right: -20,
            child: _circle(120, 0.06),
          ),
          Positioned(
            bottom: -40, right: 60,
            child: _circle(100, 0.04),
          ),
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: const Icon(Icons.receipt_long_rounded,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Billing & Payments',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${s?.totalInvoices ?? 0} invoices this month',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 16 : 20),
                // Stats grid
                isSmallScreen
                    ? Column(children: [
                        Row(children: [
                          Expanded(child: _Chip(label: 'Total Value', value: '₹${fmt.format(s?.totalValue ?? 0)}', icon: Icons.currency_rupee_rounded, isHighlight: true)),
                          const SizedBox(width: 10),
                          Expanded(child: _Chip(label: 'Collected', value: '₹${fmt.format(s?.totalCollected ?? 0)}', icon: Icons.check_circle_rounded)),
                        ]),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(child: _Chip(label: 'Pending', value: '₹${fmt.format(s?.totalPending ?? 0)}', icon: Icons.pending_rounded)),
                          const SizedBox(width: 10),
                          Expanded(child: _Chip(label: 'Invoices', value: '${s?.totalInvoices ?? 0}', icon: Icons.description_rounded)),
                        ]),
                      ])
                    : Row(children: [
                        Expanded(child: _Chip(label: 'Total Value', value: '₹${fmt.format(s?.totalValue ?? 0)}', icon: Icons.currency_rupee_rounded, isHighlight: true)),
                        const SizedBox(width: 12),
                        Expanded(child: _Chip(label: 'Collected', value: '₹${fmt.format(s?.totalCollected ?? 0)}', icon: Icons.check_circle_rounded)),
                        const SizedBox(width: 12),
                        Expanded(child: _Chip(label: 'Pending', value: '₹${fmt.format(s?.totalPending ?? 0)}', icon: Icons.pending_rounded)),
                        const SizedBox(width: 12),
                        Expanded(child: _Chip(label: 'Invoices', value: '${s?.totalInvoices ?? 0}', icon: Icons.description_rounded)),
                      ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, double opacity) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      );
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isHighlight;

  const _Chip({
    required this.label,
    required this.value,
    required this.icon,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
          Icon(icon,
              color: isHighlight ? const Color(0xFFF39C12) : Colors.white70,
              size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: isHighlight ? const Color(0xFFF39C12) : Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6), fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}